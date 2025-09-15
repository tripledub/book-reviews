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

  when :redis
    require_relative "../../lib/cache_service/redis_cache"
    # RedisCache accepts redis-specific options with correct parameter names
    redis_options = {
      url: cache_options[:redis_url],
      timeout: cache_options[:redis_timeout]
    }.compact
    CacheService.configure(CacheService::RedisCache, **redis_options)

  when :null, :none
    require_relative "../../lib/cache_service/null_cache"
    # NullCache doesn't accept any options
    CacheService.configure(CacheService::NullCache)

  else
    raise ArgumentError, "Unknown cache backend: #{cache_backend}. Supported backends: :memory, :redis, :null, :none"
  end
end

# Log cache configuration on startup
Rails.logger.info("[CacheService] Configured with backend: #{CacheService.backend.class.name}") if Rails.logger
