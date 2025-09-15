# frozen_string_literal: true

# NullCache provides a no-op cache implementation that always executes
# the block and never stores anything. Useful for disabling caching
# without changing service layer code.
#
# @example Usage
#   CacheService.backend = NullCache.new
#   CacheService.fetch('key', expires_in: 1.hour) { expensive_operation }
#   # Always executes expensive_operation, never caches result
class CacheService::NullCache < CacheService::Base
  # Always executes the block and returns its result
  # Never stores anything in cache
  #
  # @param key [String] Cache key (ignored)
  # @param expires_in [Integer, nil] Expiration time (ignored)
  # @yield Block to execute
  # @return [Object] Result of the block
  def fetch(key, expires_in: nil, &block)
    block.call
  end

  # No-op: does nothing
  #
  # @param key [String] Cache key (ignored)
  # @param value [Object] Value to store (ignored)
  # @param expires_in [Integer, nil] Expiration time (ignored)
  # @return [Boolean] Always returns true
  def write(key, value, expires_in: nil)
    true
  end

  # Always returns nil (cache miss)
  #
  # @param key [String] Cache key (ignored)
  # @return [nil] Always returns nil
  def read(key)
    nil
  end

  # Always returns nil (cache miss) - alias for read
  #
  # @param key [String] Cache key (ignored)
  # @return [nil] Always returns nil
  def get(key)
    nil
  end

  # No-op: does nothing - alias for write
  #
  # @param key [String] Cache key (ignored)
  # @param value [Object] Value to store (ignored)
  # @param expires_in [Integer, nil] Expiration time (ignored)
  # @return [Boolean] Always returns true
  def set(key, value, expires_in: nil)
    true
  end

  # No-op: does nothing
  #
  # @param key [String] Cache key (ignored)
  # @return [Boolean] Always returns true
  def delete(key)
    true
  end

  # No-op: does nothing
  #
  # @return [Boolean] Always returns true
  def clear
    true
  end

  # Always returns empty array
  #
  # @param pattern [String] Pattern to match (ignored)
  # @return [Array] Always returns empty array
  def keys(pattern = nil)
    []
  end

  # No-op: does nothing
  #
  # @param keys [Array] Keys to delete (ignored)
  # @return [Integer] Always returns 0
  def delete_many(keys)
    0
  end

  # Always returns false (no keys exist)
  #
  # @param key [String] Cache key (ignored)
  # @return [Boolean] Always returns false
  def exists?(key)
    false
  end

  # Always returns 0 (no keys exist)
  #
  # @return [Integer] Always returns 0
  def size
    0
  end
end
