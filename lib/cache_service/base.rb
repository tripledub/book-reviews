# frozen_string_literal: true

# Base class for cache backend implementations
# Provides the interface that all cache backends must implement
#
# @abstract Subclass and override all methods to implement a cache backend
# @see CacheService::MemoryCache for an example implementation
# @see CacheService::RedisCache for an example implementation
class CacheService::Base
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
