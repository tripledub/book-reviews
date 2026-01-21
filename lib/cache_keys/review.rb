# frozen_string_literal: true

# CacheKeys::Review provides cache key generation for review-related operations
# Follows consistent naming pattern: book_review:review:action:params:origin=api
#
# @example Basic usage
#   CacheKeys::Review.find(123)
#   CacheKeys::Review.paginated(page: 1, limit: 20)
#   CacheKeys::Review.search("amazing", page: 1, limit: 20)
#
# @example Pattern-based invalidation
#   pattern = CacheKeys::Review.pattern
#   keys = CacheService.keys(pattern)
#   CacheService.delete(keys)
module CacheKeys
  module Review
    # Generate cache key for finding a specific review
    #
    # @param id [Integer] Review ID
    # @return [String] Cache key for the review
    def self.find(id)
      "book_review:review:find:id=#{id}:origin=api"
    end

    # Generate cache key for paginated reviews list
    #
    # @param page [Integer] Page number (default: 1)
    # @param limit [Integer] Items per page (default: 20)
    # @return [String] Cache key for paginated reviews
    def self.paginated(page: 1, limit: 20)
      "book_review:review:paginated:page=#{page}:limit=#{limit}:origin=api"
    end

    # Generate cache key for review search results
    #
    # @param query [String] Search query
    # @param page [Integer] Page number (default: 1)
    # @param limit [Integer] Items per page (default: 20)
    # @return [String] Cache key for search results
    def self.search(query, page: 1, limit: 20)
      # Use MD5 hash for consistent, case-insensitive cache keys
      query_hash = Digest::MD5.hexdigest(query.downcase.strip)
      "book_review:review:search:query=#{query_hash}:page=#{page}:limit=#{limit}:origin=api"
    end

    # Generate cache key for reviews by book
    #
    # @param book_id [Integer] Book ID
    # @return [String] Cache key for reviews by book
    def self.by_book(book_id)
      "book_review:review:by_book:book_id=#{book_id}:origin=api"
    end

    # Generate cache key for reviews by score range
    #
    # @param min_score [Integer] Minimum score
    # @param max_score [Integer] Maximum score (default: 5)
    # @return [String] Cache key for reviews by score
    def self.by_score(min_score:, max_score: 5)
      "book_review:review:by_score:min=#{min_score}:max=#{max_score}:origin=api"
    end

    # Generate cache key for high-rated reviews
    #
    # @return [String] Cache key for high-rated reviews
    def self.high_rated
      "book_review:review:high_rated:origin=api"
    end

    # Generate cache key for low-rated reviews
    #
    # @return [String] Cache key for low-rated reviews
    def self.low_rated
      "book_review:review:low_rated:origin=api"
    end

    # Generate cache key for recent reviews
    #
    # @param limit [Integer] Maximum number of reviews (default: 10)
    # @return [String] Cache key for recent reviews
    def self.recent(limit: 10)
      "book_review:review:recent:limit=#{limit}:origin=api"
    end

    # Generate cache key for reviews for multiple books
    #
    # @param book_ids [Array<Integer>] Array of book IDs
    # @return [String] Cache key for reviews for multiple books
    def self.for_books(book_ids)
      sorted_ids = book_ids.sort.join(",")
      "book_review:review:for_books:ids=#{sorted_ids}:origin=api"
    end

    # Generate pattern for all review cache keys
    #
    # @return [String] Pattern to match all review cache keys
    def self.pattern
      "book_review:review:*"
    end

    # Generate pattern for specific review cache keys
    #
    # @param id [Integer] Review ID
    # @return [String] Pattern to match cache keys for specific review
    def self.pattern_for_review(id)
      "book_review:review:*:id=#{id}:*"
    end

    # Generate pattern for reviews by book cache keys
    #
    # @param book_id [Integer] Book ID
    # @return [String] Pattern to match cache keys for reviews by book
    def self.pattern_for_book(book_id)
      "book_review:review:*:book_id=#{book_id}:*"
    end

    # Generate pattern for search cache keys
    #
    # @return [String] Pattern to match all search cache keys
    def self.search_pattern
      "book_review:review:search:*"
    end
  end
end
