# frozen_string_literal: true

# CacheService provides a unified interface for caching operations
# across different backend implementations (Memory, File, Redis, etc.)
#
# @example Basic usage
#   CacheService.fetch(CacheKeys.book(123), expires_in: 1.hour) do
#     Book.find(123)
#   end
#
# @example Setting cache directly
#   CacheService.set(CacheKeys.book(123), book_data, expires_in: 1.hour)
#
# @example Deleting cache
#   CacheService.delete(CacheKeys.book(123))
module CacheService
  # Default cache backend - will be set by configuration
  @backend = nil

  class << self
    attr_accessor :backend

    # Fetch data from cache or execute block if cache miss
    #
    # @param key [String] Cache key
    # @param expires_in [Integer, ActiveSupport::Duration] TTL in seconds
    # @yield Block to execute on cache miss
    # @return [Object] Cached data or block result
    def fetch(key, expires_in: nil, &block)
      raise ArgumentError, "Block required for fetch operation" unless block_given?

      result = get(key)

      if result.nil?
        Rails.logger.info("[CacheService] Cache miss for key: #{key}") if Rails.logger
        result = yield
        set(key, result, expires_in: expires_in) if result
      else
        Rails.logger.info("[CacheService] Cache hit for key: #{key}") if Rails.logger
      end

      result
    end

    # Get data from cache
    #
    # @param key [String] Cache key
    # @return [Object, nil] Cached data or nil if not found/expired
    def get(key)
      backend.get(key)
    end

    # Set data in cache
    #
    # @param key [String] Cache key
    # @param value [Object] Data to cache
    # @param expires_in [Integer, ActiveSupport::Duration] TTL in seconds
    # @return [Boolean] Success status
    def set(key, value, expires_in: nil)
      backend.set(key, value, expires_in: expires_in)
    end

    # Delete data from cache
    #
    # @param keys [String, Array<String>] Cache key(s) to delete
    # @return [Integer] Number of keys deleted
    def delete(*keys)
      keys.flatten!
      return 0 if keys.empty?

      backend.delete(keys)
    end

    # Check if key exists in cache
    #
    # @param key [String] Cache key
    # @return [Boolean] True if key exists and not expired
    def exists?(key)
      backend.exists?(key)
    end

    # Clear all cache
    #
    # @return [Boolean] Success status
    def clear
      backend.clear
    end

    # Get cache statistics
    #
    # @return [Hash] Cache statistics
    def stats
      backend.stats
    end

    # Configure the cache backend
    #
    # @param backend_class [Class] Backend implementation class
    # @param options [Hash] Backend-specific configuration options
    def configure(backend_class, **options)
      self.backend = backend_class.new(**options)
    end

    # Ensure backend is configured
    def backend
      @backend ||= default_backend
    end

    private

    # Default backend for development/test
    def default_backend
      case Rails.env
      when "test"
        require_relative "cache_service/memory_cache"
        MemoryCache.new
      when "development"
        require_relative "cache_service/memory_cache"
        MemoryCache.new
      else
        require_relative "cache_service/file_cache"
        FileCache.new
      end
    end
  end

  # Base class for cache backend implementations
  class Base
    # Get data from cache
    #
    # @param key [String] Cache key
    # @return [Object, nil] Cached data or nil if not found/expired
    def get(key)
      raise NotImplementedError, "Subclasses must implement #get"
    end

    # Set data in cache
    #
    # @param key [String] Cache key
    # @param value [Object] Data to cache
    # @param expires_in [Integer, ActiveSupport::Duration] TTL in seconds
    # @return [Boolean] Success status
    def set(key, value, expires_in: nil)
      raise NotImplementedError, "Subclasses must implement #set"
    end

    # Delete data from cache
    #
    # @param keys [Array<String>] Cache keys to delete
    # @return [Integer] Number of keys deleted
    def delete(keys)
      raise NotImplementedError, "Subclasses must implement #delete"
    end

    # Check if key exists in cache
    #
    # @param key [String] Cache key
    # @return [Boolean] True if key exists and not expired
    def exists?(key)
      raise NotImplementedError, "Subclasses must implement #exists?"
    end

    # Clear all cache
    #
    # @return [Boolean] Success status
    def clear
      raise NotImplementedError, "Subclasses must implement #clear"
    end

    # Get cache statistics
    #
    # @return [Hash] Cache statistics
    def stats
      raise NotImplementedError, "Subclasses must implement #stats"
    end

    # Find keys matching pattern
    #
    # @param pattern [String] Key pattern (supports wildcards)
    # @return [Array<String>] Matching keys
    def keys(pattern = "*")
      raise NotImplementedError, "Subclasses must implement #keys"
    end

    protected

    # Serialize value for storage
    #
    # @param value [Object] Value to serialize
    # @return [String] Serialized value
    def serialize(value)
      Marshal.dump(value)
    end

    # Deserialize value from storage
    #
    # @param data [String] Serialized data
    # @return [Object] Deserialized value
    def deserialize(data)
      Marshal.load(data)
    end

    # Convert expires_in to seconds
    #
    # @param expires_in [Integer, ActiveSupport::Duration, nil] TTL
    # @return [Integer, nil] TTL in seconds
    def normalize_expires_in(expires_in)
      return nil if expires_in.nil?

      case expires_in
      when Integer
        expires_in
      when ActiveSupport::Duration
        expires_in.to_i
      else
        expires_in.to_i
      end
    end
  end
end
