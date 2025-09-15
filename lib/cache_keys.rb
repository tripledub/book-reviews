# frozen_string_literal: true

# CacheKeys module provides a centralized, standardized approach to generating
# and managing cache keys throughout the Book Review application.
#
# It ensures consistency, maintainability, and proper cache invalidation
# across the entire application.
#
# @example Basic usage
#   CacheKeys::Book.find(123)
#   CacheKeys::Book.paginated(page: 1, limit: 20)
#   CacheKeys::Review.search("amazing", page: 1, limit: 20)
#
# @example Pattern-based invalidation
#   pattern = CacheKeys::Book.pattern
#   keys = CacheService.keys(pattern)
#   CacheService.delete(keys)
module CacheKeys
  # Load the namespaced cache key modules
  require_relative "cache_keys/book"
  require_relative "cache_keys/review"

  # Pattern-based key discovery for cache invalidation
  #
  # @param pattern [String] Redis key pattern (supports wildcards)
  # @param cache_service [Object] Cache service to use (defaults to CacheService)
  # @return [Array<String>] Array of matching cache keys
  def self.keys(pattern = "*", cache_service: CacheService)
    cache_service.keys(pattern)
  end

  # Clear all cache keys matching a pattern
  #
  # @param pattern [String] Pattern to match keys for deletion
  # @param cache_service [Object] Cache service to use (defaults to CacheService)
  # @return [Integer] Number of keys deleted
  def self.clear_pattern(pattern, cache_service: CacheService)
    keys = self.keys(pattern, cache_service: cache_service)
    return 0 if keys.empty?

    cache_service.delete(keys)
  end

  # Clear all cache (use with caution!)
  #
  # @return [Integer] Number of keys deleted
  def self.clear_all_cache
    clear_pattern("book_review:*")
  end
end
