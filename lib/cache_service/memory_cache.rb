# frozen_string_literal: true

# MemoryCache provides an in-memory cache implementation
# Perfect for development and testing environments
#
# @example Usage
#   cache = MemoryCache.new
#   cache.set("key", "value", expires_in: 3600)
#   cache.get("key") # => "value"
class CacheService::MemoryCache < CacheService::Base
  def initialize
    @store = {}
    @expires = {}
    @mutex = Mutex.new
  end

  # Get data from cache
  #
  # @param key [String] Cache key
  # @return [Object, nil] Cached data or nil if not found/expired
  def get(key)
    @mutex.synchronize do
      return nil unless @store.key?(key)

      # Check if expired
      if @expires[key] && Time.now > @expires[key]
        @store.delete(key)
        @expires.delete(key)
        return nil
      end

      deserialize(@store[key])
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
      @store[key] = serialize(value)

      if expires_in
        @expires[key] = Time.now + normalize_expires_in(expires_in)
      else
        @expires.delete(key) # No expiration
      end

      true
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
        if @store.key?(key)
          @store.delete(key)
          @expires.delete(key)
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
      return false unless @store.key?(key)

      # Check if expired
      if @expires[key] && Time.now > @expires[key]
        @store.delete(key)
        @expires.delete(key)
        return false
      end

      true
    end
  end

  # Clear all cache
  #
  # @return [Boolean] Success status
  def clear
    @mutex.synchronize do
      @store.clear
      @expires.clear
      true
    end
  end

  # Get cache statistics
  #
  # @return [Hash] Cache statistics
  def stats
    @mutex.synchronize do
      now = Time.now
      expired_keys = @expires.select { |_, expiry| expiry < now }.keys

      # Clean up expired keys
      expired_keys.each do |key|
        @store.delete(key)
        @expires.delete(key)
      end

      {
        total_keys: @store.size,
        expired_keys: expired_keys.size,
        memory_usage: estimate_memory_usage,
        backend: "MemoryCache"
      }
    end
  end

  # Find keys matching pattern
  #
  # @param pattern [String] Key pattern (supports wildcards)
  # @return [Array<String>] Matching keys
  def keys(pattern = "*")
    @mutex.synchronize do
      # Clean up expired keys first
      now = Time.now
      expired_keys = @expires.select { |_, expiry| expiry < now }.keys
      expired_keys.each do |key|
        @store.delete(key)
        @expires.delete(key)
      end

      # Convert glob pattern to regex
      regex_pattern = pattern.gsub("*", ".*").gsub("?", ".")
      regex = Regexp.new("^#{regex_pattern}$")

      @store.keys.select { |key| regex.match?(key) }
    end
  end

  private

  # Estimate memory usage of the cache
  #
  # @return [Integer] Estimated memory usage in bytes
  def estimate_memory_usage
    total_size = 0

    @store.each do |key, value|
      total_size += key.bytesize
      total_size += value.bytesize
    end

    @expires.each do |key, _|
      total_size += key.bytesize
      total_size += 8 # Time object size estimate
    end

    total_size
  end
end
