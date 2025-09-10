# frozen_string_literal: true

# CacheService configuration
# Configure the cache backend based on environment and settings

# Load the main modules first
require_relative "../../lib/cache_service"
require_relative "../../lib/cache_keys"

Rails.application.configure do
  # Configure cache backend based on environment configuration
  cache_backend = Rails.application.config.book_review_cache_backend
  cache_options = Rails.application.config.book_review_cache_options || {}

  case cache_backend
  when :memory
    require_relative "../../lib/cache_service/memory_cache"
    # MemoryCache doesn't accept any options
    CacheService.configure(CacheService::MemoryCache)

  when :file
    require_relative "../../lib/cache_service/file_cache"
    # FileCache only accepts cache_dir option
    file_options = cache_options.slice(:cache_dir)
    CacheService.configure(CacheService::FileCache, **file_options)

  when :redis
    # Redis implementation would go here
    # require_relative '../../lib/cache_service/redis_cache'
    # CacheService.configure(CacheService::RedisCache, **cache_options)

    # For now, fall back to file cache
    Rails.logger.warn("[CacheService] Redis backend not implemented, falling back to file cache")
    require_relative "../../lib/cache_service/file_cache"
    CacheService.configure(CacheService::FileCache, **cache_options)

  else
    raise ArgumentError, "Unknown cache backend: #{cache_backend}. Supported backends: :memory, :file, :redis"
  end
end

# Configure CacheKeys to use the configured backend
module CacheKeys
  # Override the keys method to use the configured backend
  def self.keys(pattern = "*")
    CacheService.backend.keys(pattern)
  end

  # Override the clear_pattern method to use the configured backend
  def self.clear_pattern(pattern)
    keys = self.keys(pattern)
    return 0 if keys.empty?

    CacheService.delete(keys)
  end
end

# Log cache configuration on startup
Rails.logger.info("[CacheService] Configured with backend: #{CacheService.backend.class.name}") if Rails.logger
