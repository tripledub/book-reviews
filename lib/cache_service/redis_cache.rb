# frozen_string_literal: true

# RedisCache provides a Redis-based cache implementation
# Perfect for production environments with high performance requirements
#
# @example Usage
#   cache = RedisCache.new(url: 'redis://localhost:6379/0')
#   cache.set("key", "value", expires_in: 3600)
#   cache.get("key") # => "value"
class CacheService::RedisCache < CacheService::Base
  def initialize(url: "redis://localhost:6379/0", timeout: 5)
    @redis_url = url
    @timeout = timeout

    @redis = nil
    @mutex = Mutex.new

    ensure_connection
  end

  # Get data from cache
  #
  # @param key [String] Cache key
  # @return [Object, nil] Cached data or nil if not found/expired
  def get(key)
    with_connection do |redis|
      data = redis.get(key)
      return nil if data.nil?

      data
    end
  rescue => e
    Rails.logger.error("[RedisCache] Error getting key #{key}: #{e.message}") if Rails.logger
    nil
  end

  # Set data in cache
  #
  # @param key [String] Cache key
  # @param value [Object] Data to cache
  # @param expires_in [Integer, ActiveSupport::Duration] TTL in seconds
  # @return [Boolean] Success status
  def set(key, value, expires_in: nil)
    with_connection do |redis|
      if expires_in
        ttl = normalize_expires_in(expires_in)
        redis.setex(key, ttl, value)
      else
        redis.set(key, value)
      end

      true
    end
  rescue => e
    Rails.logger.error("[RedisCache] Error setting key #{key}: #{e.message}") if Rails.logger
    false
  end

  # Delete data from cache
  #
  # @param keys [Array<String>] Cache keys to delete
  # @return [Integer] Number of keys deleted
  def delete(keys)
    return 0 if keys.empty?

    with_connection do |redis|
      redis.del(*keys)
    end
  rescue => e
    Rails.logger.error("[RedisCache] Error deleting keys #{keys}: #{e.message}") if Rails.logger
    0
  end

  # Check if key exists in cache
  #
  # @param key [String] Cache key
  # @return [Boolean] True if key exists and not expired
  def exists?(key)
    with_connection do |redis|
      redis.exists?(key)
    end
  rescue => e
    Rails.logger.error("[RedisCache] Error checking existence of key #{key}: #{e.message}") if Rails.logger
    false
  end

  # Clear all cache
  #
  # @return [Boolean] Success status
  def clear
    with_connection do |redis|
      redis.flushdb
      true
    end
  rescue => e
    Rails.logger.error("[RedisCache] Error clearing cache: #{e.message}") if Rails.logger
    false
  end

  # Get cache statistics
  #
  # @return [Hash] Cache statistics
  def stats
    with_connection do |redis|
      info = redis.info

      {
        total_keys: redis.dbsize,
        used_memory: info["used_memory_human"],
        connected_clients: info["connected_clients"],
        total_commands_processed: info["total_commands_processed"],
        keyspace_hits: info["keyspace_hits"],
        keyspace_misses: info["keyspace_misses"],
        backend: "RedisCache",
        redis_version: info["redis_version"],
        uptime_in_seconds: info["uptime_in_seconds"]
      }
    end
  rescue => e
    Rails.logger.error("[RedisCache] Error getting stats: #{e.message}") if Rails.logger
    {
      total_keys: 0,
      used_memory: "unknown",
      connected_clients: 0,
      total_commands_processed: 0,
      keyspace_hits: 0,
      keyspace_misses: 0,
      backend: "RedisCache",
      redis_version: "unknown",
      uptime_in_seconds: 0
    }
  end

  # Find keys matching pattern
  #
  # @param pattern [String] Key pattern (supports wildcards)
  # @return [Array<String>] Matching keys
  def keys(pattern = "*")
    matching_keys = []
    cursor = 0
    max_iterations = 1000  # Safety limit to prevent infinite loops
    iteration_count = 0
    seen_cursors = Set.new  # Track seen cursors to detect infinite loops

    with_connection do |redis|
      loop do
        iteration_count += 1
        break if iteration_count > max_iterations

        # Check for infinite loop by tracking seen cursors
        if seen_cursors.include?(cursor)
          Rails.logger.warn("[RedisCache] Infinite loop detected in SCAN for pattern #{pattern}, cursor: #{cursor}") if Rails.logger
          break
        end
        seen_cursors.add(cursor)

        cursor, keys = redis.scan(cursor, match: pattern, count: 1000)
        matching_keys.concat(keys)

        # Break if cursor is 0 (scan complete)
        break if cursor == 0
      end

      if iteration_count > max_iterations
        Rails.logger.warn("[RedisCache] SCAN operation hit safety limit for pattern #{pattern}") if Rails.logger
      end
    end

    matching_keys.uniq  # Remove duplicates as a safety measure
  rescue => e
    Rails.logger.error("[RedisCache] Error scanning keys with pattern #{pattern}: #{e.message}") if Rails.logger
    []
  end

  private

  # Ensure Redis connection is established
  def ensure_connection
    @mutex.synchronize do
      return if @redis && @redis.ping == "PONG"

      @redis = Redis.new(
        url: @redis_url,
        timeout: @timeout
      )

      # Test connection
      @redis.ping
    end
  rescue => e
    Rails.logger.error("[RedisCache] Failed to connect to Redis: #{e.message}") if Rails.logger
    raise e
  end

  # Execute block with Redis connection, handling reconnection
  def with_connection(&block)
    ensure_connection
    block.call(@redis)
  rescue Redis::ConnectionError, Redis::TimeoutError => e
    Rails.logger.warn("[RedisCache] Connection error, attempting reconnection: #{e.message}") if Rails.logger
    @redis = nil
    ensure_connection
    block.call(@redis)
  end
end
