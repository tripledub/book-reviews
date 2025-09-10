# frozen_string_literal: true

# CacheKeys module provides a centralized, standardized approach to generating
# and managing cache keys throughout the Book Review application.
#
# It ensures consistency, maintainability, and proper cache invalidation
# across the entire application.
#
# @example Basic usage
#   CacheKeys.books(page: 1, limit: 20)
#   CacheKeys.book(123)
#   CacheKeys.search_books("ruby programming")
#
# @example Pattern-based invalidation
#   pattern = CacheKeys.books
#   keys = CacheKeys.keys(pattern)
#   CacheService.delete(keys)
module CacheKeys
  # Core key generation methods for books
  #
  # @param page [Integer] Page number for pagination
  # @param limit [Integer] Number of items per page
  # @return [String] Cache key for books list
  def self.books(page: 1, limit: 20)
    "book_review:books:page=#{page}:limit=#{limit}:origin=api"
  end

  # Generate cache key for a specific book
  #
  # @param id [Integer] Book ID
  # @return [String] Cache key for specific book
  def self.book(id)
    "book_review:book:id=#{id}:origin=api"
  end

  # Generate cache key for book search results
  #
  # @param query [String] Search query
  # @return [String] Cache key for search results
  def self.search_books(query)
    query_hash = Digest::MD5.hexdigest(query.downcase.strip)
    "book_review:search:query=#{query_hash}:origin=api"
  end

  # Generate cache key for book reviews
  #
  # @param book_id [Integer] Book ID
  # @return [String] Cache key for book reviews
  def self.reviews(book_id)
    "book_review:reviews:book_id=#{book_id}:origin=api"
  end

  # Generate cache key for review statistics
  #
  # @param book_id [Integer] Book ID
  # @return [String] Cache key for review statistics
  def self.review_stats(book_id)
    "book_review:review_stats:book_id=#{book_id}:origin=api"
  end

  # Generate cache key for highly rated books
  #
  # @param limit [Integer] Number of books to return
  # @return [String] Cache key for highly rated books
  def self.highly_rated_books(limit: 10)
    "book_review:highly_rated:limit=#{limit}:origin=api"
  end

  # Generate cache key for recent books
  #
  # @param limit [Integer] Number of books to return
  # @return [String] Cache key for recent books
  def self.recent_books(limit: 10)
    "book_review:recent:limit=#{limit}:origin=api"
  end

  # Pattern-based key discovery for cache invalidation
  #
  # @param pattern [String] Redis key pattern (supports wildcards)
  # @return [Array<String>] Array of matching cache keys
  def self.keys(pattern = "*")
    CacheService.keys(pattern)
  end

  # Generate pattern for all book-related keys
  #
  # @return [String] Pattern to match all book keys
  def self.books_pattern
    "book_review:books:*"
  end

  # Generate pattern for all search-related keys
  #
  # @return [String] Pattern to match all search keys
  def self.search_pattern
    "book_review:search:*"
  end

  # Generate pattern for all review-related keys
  #
  # @return [String] Pattern to match all review keys
  def self.reviews_pattern
    "book_review:reviews:*"
  end

  # Generate pattern for all statistics-related keys
  #
  # @return [String] Pattern to match all statistics keys
  def self.stats_pattern
    "book_review:review_stats:*"
  end

  # Generate pattern for all highly rated book keys
  #
  # @return [String] Pattern to match all highly rated book keys
  def self.highly_rated_pattern
    "book_review:highly_rated:*"
  end

  # Generate pattern for all recent book keys
  #
  # @return [String] Pattern to match all recent book keys
  def self.recent_pattern
    "book_review:recent:*"
  end

  # Clear all cache keys matching a pattern
  #
  # @param pattern [String] Pattern to match keys for deletion
  # @return [Integer] Number of keys deleted
  def self.clear_pattern(pattern)
    keys = self.keys(pattern)
    return 0 if keys.empty?

    CacheService.delete(keys)
  end

  # Clear all book-related cache
  #
  # @return [Integer] Number of keys deleted
  def self.clear_books_cache
    clear_pattern(books_pattern)
  end

  # Clear all search-related cache
  #
  # @return [Integer] Number of keys deleted
  def self.clear_search_cache
    clear_pattern(search_pattern)
  end

  # Clear all review-related cache
  #
  # @return [Integer] Number of keys deleted
  def self.clear_reviews_cache
    clear_pattern(reviews_pattern)
  end

  # Clear all statistics-related cache
  #
  # @return [Integer] Number of keys deleted
  def self.clear_stats_cache
    clear_pattern(stats_pattern)
  end

  # Clear all highly rated book cache
  #
  # @return [Integer] Number of keys deleted
  def self.clear_highly_rated_cache
    clear_pattern(highly_rated_pattern)
  end

  # Clear all recent book cache
  #
  # @return [Integer] Number of keys deleted
  def self.clear_recent_cache
    clear_pattern(recent_pattern)
  end

  # Clear all cache for a specific book
  #
  # @param book_id [Integer] Book ID
  # @return [Integer] Number of keys deleted
  def self.clear_book_cache(book_id)
    keys = [
      book(book_id),
      reviews(book_id),
      review_stats(book_id)
    ]

    CacheService.delete(keys)
  end

  # Clear all cache (use with caution!)
  #
  # @return [Integer] Number of keys deleted
  def self.clear_all_cache
    clear_pattern("book_review:*")
  end
end
