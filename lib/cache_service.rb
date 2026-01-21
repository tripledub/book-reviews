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
  # Load the base class
  require_relative "cache_service/base"
  # Error raised when CacheService is used without being configured
  class NotConfiguredError < StandardError; end

  # Default cache backend - will be set by configuration
  @backend = nil

  class << self
    attr_accessor :backend

    # Fetch data from cache or execute block if cache miss
    #
    # @param key [String] Cache key
    # @param expires_in [Integer, ActiveSupport::Duration] TTL in seconds
    # @yield Block to execute on cache miss
    # @return [Object] Cached data or block result (always Ruby objects)
    def fetch(key, expires_in: nil, &block)
      raise ArgumentError, "Block required for fetch operation" unless block_given?

      # Get serialized data from backend
      serialized_result = backend.get(key)

      if serialized_result.nil?
        Rails.logger.info("[CacheService] Cache miss for key: #{key}") if Rails.logger
        result = yield
        set(key, result, expires_in: expires_in) if result
      else
        Rails.logger.info("[CacheService] Cache hit for key: #{key}") if Rails.logger
        # Deserialize the cached data back to Ruby objects
        result = Marshal.load(serialized_result)
      end

      result
    end

    # Get data from cache
    #
    # @param key [String] Cache key
    # @return [Object, nil] Cached data or nil if not found/expired (always Ruby objects)
    def get(key)
      serialized_data = backend.get(key)
      return nil if serialized_data.nil?

      Marshal.load(serialized_data)
    end

    # Set data in cache
    #
    # @param key [String] Cache key
    # @param value [Object] Data to cache (will be serialized)
    # @param expires_in [Integer, ActiveSupport::Duration] TTL in seconds
    # @return [Boolean] Success status
    def set(key, value, expires_in: nil)
      # Serialize the value before storing
      serialized_value = Marshal.dump(value)
      backend.set(key, serialized_value, expires_in: expires_in)
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

    # Find keys matching pattern
    #
    # @param pattern [String] Key pattern (supports wildcards)
    # @return [Array<String>] Matching keys
    def keys(pattern = "*")
      backend.keys(pattern)
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
      @backend || raise(NotConfiguredError, "CacheService backend not configured. Please configure it in config/initializers/cache_service.rb")
    end
  end
end
