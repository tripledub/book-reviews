# frozen_string_literal: true

# CacheKeys::Book provides cache key generation for book-related operations
# Follows consistent naming pattern: book_review:book:action:params:origin=api
#
# @example Basic usage
#   CacheKeys::Book.find(123)
#   CacheKeys::Book.paginated(page: 1, limit: 20)
#   CacheKeys::Book.search("ruby", page: 1, limit: 20)
#
# @example Pattern-based invalidation
#   pattern = CacheKeys::Book.pattern
#   keys = CacheService.keys(pattern)
#   CacheService.delete(keys)
module CacheKeys
  module Book
    # Generate cache key for finding a specific book
    #
    # @param id [Integer] Book ID
    # @return [String] Cache key for the book
    def self.find(id)
      "book_review:book:find:id=#{id}:origin=api"
    end

    # Generate cache key for paginated books list
    #
    # @param page [Integer] Page number (default: 1)
    # @param limit [Integer] Items per page (default: 20)
    # @return [String] Cache key for paginated books
    def self.paginated(page: 1, limit: 20)
      "book_review:book:paginated:page=#{page}:limit=#{limit}:origin=api"
    end

    # Generate cache key for book search results
    #
    # @param query [String] Search query
    # @param page [Integer] Page number (default: 1)
    # @param limit [Integer] Items per page (default: 20)
    # @return [String] Cache key for search results
    def self.search(query, page: 1, limit: 20)
      # Use MD5 hash for consistent, case-insensitive cache keys
      query_hash = Digest::MD5.hexdigest(query.downcase.strip)
      "book_review:book:search:query=#{query_hash}:page=#{page}:limit=#{limit}:origin=api"
    end

    # Generate cache key for highly rated books
    #
    # @param limit [Integer] Maximum number of books (default: 10)
    # @return [String] Cache key for highly rated books
    def self.highly_rated(limit: 10)
      "book_review:book:highly_rated:limit=#{limit}:origin=api"
    end

    # Generate cache key for recent books
    #
    # @param limit [Integer] Maximum number of books (default: 10)
    # @return [String] Cache key for recent books
    def self.recent(limit: 10)
      "book_review:book:recent:limit=#{limit}:origin=api"
    end

    # Generate cache key for books by subject
    #
    # @param subject [String] Subject to filter by
    # @return [String] Cache key for books by subject
    def self.by_subject(subject)
      sanitized_subject = subject.gsub(/[^a-zA-Z0-9\s]/, "").strip.gsub(/\s+/, "_")
      "book_review:book:by_subject:subject=#{sanitized_subject}:origin=api"
    end

    # Generate cache key for books by language
    #
    # @param language [String] Language to filter by
    # @return [String] Cache key for books by language
    def self.by_language(language)
      "book_review:book:by_language:language=#{language}:origin=api"
    end

    # Generate pattern for all book cache keys
    #
    # @return [String] Pattern to match all book cache keys
    def self.pattern
      "book_review:book:*"
    end

    # Generate pattern for specific book cache keys
    #
    # @param id [Integer] Book ID
    # @return [String] Pattern to match cache keys for specific book
    def self.pattern_for_book(id)
      "book_review:book:*:id=#{id}:*"
    end

    # Generate pattern for search cache keys
    #
    # @return [String] Pattern to match all search cache keys
    def self.search_pattern
      "book_review:book:search:*"
    end

    # Clear all book-related cache
    #
    # @return [Integer] Number of cache keys deleted
    def self.clear_all
      require_relative "../cache_service"
      pattern = self.pattern
      keys = CacheService.keys(pattern)
      keys.any? ? CacheService.delete(keys) : 0
    end

    # Clear search cache
    #
    # @return [Integer] Number of cache keys deleted
    def self.clear_search
      require_relative "../cache_service"
      pattern = self.search_pattern
      keys = CacheService.keys(pattern)
      keys.any? ? CacheService.delete(keys) : 0
    end
  end
end
