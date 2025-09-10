# frozen_string_literal: true

# FileCache provides a file-based cache implementation
# Good for production environments where Redis is not available
#
# @example Usage
#   cache = FileCache.new(cache_dir: '/tmp/book_review_cache')
#   cache.set("key", "value", expires_in: 3600)
#   cache.get("key") # => "value"
class CacheService::FileCache < CacheService::Base
  def initialize(cache_dir: nil)
    @cache_dir = cache_dir || default_cache_dir
    @mutex = Mutex.new

    ensure_cache_directory
  end

  # Get data from cache
  #
  # @param key [String] Cache key
  # @return [Object, nil] Cached data or nil if not found/expired
  def get(key)
    @mutex.synchronize do
      file_path = key_to_path(key)
      return nil unless File.exist?(file_path)

      begin
        File.open(file_path, "rb") do |file|
          # Read expiration time
          expires_at = file.read(8).unpack1("Q>")

          # Check if expired
          if expires_at > 0 && Time.now.to_i > expires_at
            File.delete(file_path)
            return nil
          end

          # Read and deserialize data
          data = file.read
          deserialize(data)
        end
      rescue => e
        Rails.logger.error("[FileCache] Error reading cache file #{file_path}: #{e.message}") if Rails.logger
        File.delete(file_path) if File.exist?(file_path)
        nil
      end
    end
  end

  # Set data in cache
  #
  # @param key [String] Cache key
  # @param value [Object] Data to cache
  # @param expires_in [Integer, ActiveSupport::Duration] TTL in seconds
  # @return [Boolean] Success status
  def set(key, value, expires_in: nil)
    @mutex.synchronize do
      file_path = key_to_path(key)

      begin
        File.open(file_path, "wb") do |file|
          # Write expiration time (8 bytes, big-endian)
          expires_at = expires_in ? (Time.now.to_i + normalize_expires_in(expires_in)) : 0
          file.write([ expires_at ].pack("Q>"))

          # Write serialized data
          file.write(serialize(value))
        end

        true
      rescue => e
        Rails.logger.error("[FileCache] Error writing cache file #{file_path}: #{e.message}") if Rails.logger
        false
      end
    end
  end

  # Delete data from cache
  #
  # @param keys [Array<String>] Cache keys to delete
  # @return [Integer] Number of keys deleted
  def delete(keys)
    @mutex.synchronize do
      deleted_count = 0

      keys.each do |key|
        file_path = key_to_path(key)
        if File.exist?(file_path)
          File.delete(file_path)
          deleted_count += 1
        end
      end

      deleted_count
    end
  end

  # Check if key exists in cache
  #
  # @param key [String] Cache key
  # @return [Boolean] True if key exists and not expired
  def exists?(key)
    @mutex.synchronize do
      file_path = key_to_path(key)
      return false unless File.exist?(file_path)

      begin
        File.open(file_path, "rb") do |file|
          expires_at = file.read(8).unpack1("Q>")

          if expires_at > 0 && Time.now.to_i > expires_at
            File.delete(file_path)
            return false
          end

          true
        end
      rescue => e
        Rails.logger.error("[FileCache] Error checking cache file #{file_path}: #{e.message}") if Rails.logger
        File.delete(file_path) if File.exist?(file_path)
        false
      end
    end
  end

  # Clear all cache
  #
  # @return [Boolean] Success status
  def clear
    @mutex.synchronize do
      begin
        Dir.glob(File.join(@cache_dir, "**", "*")).each do |file|
          File.delete(file) if File.file?(file)
        end

        # Remove empty directories
        Dir.glob(File.join(@cache_dir, "**", "*")).reverse_each do |dir|
          Dir.rmdir(dir) if File.directory?(dir) && Dir.empty?(dir)
        end

        true
      rescue => e
        Rails.logger.error("[FileCache] Error clearing cache: #{e.message}") if Rails.logger
        false
      end
    end
  end

  # Get cache statistics
  #
  # @return [Hash] Cache statistics
  def stats
    @mutex.synchronize do
      total_files = 0
      total_size = 0
      expired_files = 0
      now = Time.now.to_i

      Dir.glob(File.join(@cache_dir, "**", "*")).each do |file_path|
        next unless File.file?(file_path)

        total_files += 1
        total_size += File.size(file_path)

        # Check if expired
        begin
          File.open(file_path, "rb") do |file|
            expires_at = file.read(8).unpack1("Q>")
            if expires_at > 0 && now > expires_at
              expired_files += 1
            end
          end
        rescue
          # Skip files that can't be read
        end
      end

      {
        total_keys: total_files,
        expired_keys: expired_files,
        total_size: total_size,
        cache_directory: @cache_dir,
        backend: "FileCache"
      }
    end
  end

  # Find keys matching pattern
  #
  # @param pattern [String] Key pattern (supports wildcards)
  # @return [Array<String>] Matching keys
  def keys(pattern = "*")
    @mutex.synchronize do
      # Convert glob pattern to regex
      regex_pattern = pattern.gsub("*", ".*").gsub("?", ".")
      regex = Regexp.new("^#{regex_pattern}$")

      matching_keys = []

      Dir.glob(File.join(@cache_dir, "**", "*")).each do |file_path|
        next unless File.file?(file_path)

        key = path_to_key(file_path)
        next unless regex.match?(key)

        # Check if expired
        begin
          File.open(file_path, "rb") do |file|
            expires_at = file.read(8).unpack1("Q>")
            if expires_at > 0 && Time.now.to_i > expires_at
              File.delete(file_path)
              next
            end
          end
        rescue
          # Skip files that can't be read
          next
        end

        matching_keys << key
      end

      matching_keys
    end
  end

  private

  # Get default cache directory
  #
  # @return [String] Default cache directory path
  def default_cache_dir
    File.join(Rails.root, "tmp", "cache", "book_review")
  end

  # Ensure cache directory exists
  def ensure_cache_directory
    FileUtils.mkdir_p(@cache_dir) unless Dir.exist?(@cache_dir)
  end

  # Convert cache key to file path
  #
  # @param key [String] Cache key
  # @return [String] File path
  def key_to_path(key)
    # Sanitize key for filesystem
    safe_key = key.gsub(/[^a-zA-Z0-9\-_:]/, "_")

    # Create nested directory structure to avoid too many files in one directory
    hash = Digest::MD5.hexdigest(safe_key)
    subdir = hash[0..1]

    File.join(@cache_dir, subdir, "#{safe_key}.cache")
  end

  # Convert file path back to cache key
  #
  # @param file_path [String] File path
  # @return [String] Cache key
  def path_to_key(file_path)
    # Extract key from file path
    basename = File.basename(file_path, ".cache")
    basename.gsub("_", ":") # This is a simplified approach
  end
end
