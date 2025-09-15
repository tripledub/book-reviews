# Service object for managing book-related operations and queries.
# Provides a clean interface for controllers to interact with books without
# exposing complex ActiveRecord queries and business logic.
#
# @example Basic usage
#   BookService.all_books                    # Get all books with reviews
#   BookService.find_book(1)                 # Find specific book
#   BookService.create_book(title: "New Book") # Create new book
#   BookService.search_books("Tolkien")      # Search by title/author
#
# @since 1.0.0
class BookService
  class << self
    # @!group Basic Operations

    # Retrieves all books with their associated reviews, ordered by creation date
    #
    # @return [ActiveRecord::Relation] All books with eager-loaded reviews, newest first
    # @example
    #   BookService.all_books
    #   # => Returns all books with their reviews, ordered by created_at DESC
    def all_books
      Book.includes(:reviews).recent
    end

    # Retrieves books for pagination (to be used with controller's pagy method)
    #
    # @return [ActiveRecord::Relation] Books ordered by creation date (newest first)
    # @example
    #   # In controller:
    #   @pagy, @books = pagy(BookService.paginated_books)
    def paginated_books
      Book.includes(:reviews).order(created_at: :desc)
    end

    # Retrieves books for pagination with caching
    #
    # @param page [Integer] Page number (default: 1)
    # @param limit [Integer] Items per page (default: 20)
    # @return [Array<Hash>] Cached books data as JSON
    # @example
    #   BookService.cached_paginated_books(page: 1, limit: 20)
    def cached_paginated_books(page: 1, limit: 20)
      cache_key = CacheKeys::Book.paginated(page: page, limit: limit)

      CacheService.fetch(cache_key, expires_in: 1.hour) do
        Book.includes(:reviews)
            .order(created_at: :desc)
            .limit(limit)
            .offset((page - 1) * limit)
            .as_json(include: :reviews)
      end
    end

    # Finds a specific book by ID with caching
    #
    # @param id [Integer, String] The book ID to find
    # @return [Hash] The book data as JSON with reviews
    # @raise [ActiveRecord::RecordNotFound] If book with given ID doesn't exist
    # @example
    #   BookService.find_book(1)              # Find book with ID 1 (cached)
    def find_book(id)
      cache_key = CacheKeys::Book.find(id)

      CacheService.fetch(cache_key, expires_in: 2.hours) do
        Book.includes(:reviews).find(id).as_json(include: :reviews)
      end
    end

    # Creates a new book with the provided attributes
    #
    # @param attributes [Hash] The attributes for the new book
    # @option attributes [String] :title The book title (required)
    # @option attributes [String] :author The book author (required)
    # @option attributes [Array<String>] :subjects Array of subject tags
    # @option attributes [Array<String>] :languages Array of language codes
    # @option attributes [String] :image URL to book cover image
    # @return [Book] The created book (reloaded from database)
    # @raise [ActiveRecord::RecordInvalid] If validation fails
    # @example
    #   BookService.create_book(
    #     title: "The Hobbit",
    #     author: "J.R.R. Tolkien",
    #     subjects: ["Fantasy", "Fiction"],
    #     languages: ["English"]
    #   )
    def create_book(attributes)
      book = Book.new(attributes)
      book.save!
      book.reload
    end

    # @!endgroup

    # @!group Search and Filter Operations

    # Searches books by title or author using case-insensitive partial matching
    #
    # @param query [String] The search term to match against title or author
    # @return [ActiveRecord::Relation] Books matching the search query, newest first
    # @raise [ArgumentError] If query is blank or nil
    # @example
    #   BookService.search_books("Tolkien")   # Find books by Tolkien
    #   BookService.search_books("Hobbit")    # Find books with "Hobbit" in title
    def search_books(query)
      raise ArgumentError, "Search query is required" if query.blank?

      Book.includes(:reviews)
          .where("title ILIKE ? OR author ILIKE ?", "%#{query}%", "%#{query}%")
          .recent
    end

    # Searches books by title or author with caching
    #
    # @param query [String] The search term to match against title or author
    # @return [Array<Hash>] Cached search results as JSON
    # @raise [ArgumentError] If query is blank or nil
    # @example
    #   BookService.cached_search_books("Tolkien")   # Find books by Tolkien (cached)
    def cached_search_books(query, page: 1, limit: 20)
      raise ArgumentError, "Search query is required" if query.blank?

      cache_key = CacheKeys::Book.search(query, page: page, limit: limit)

      CacheService.fetch(cache_key, expires_in: 30.minutes) do
        Book.includes(:reviews)
            .where("title ILIKE ? OR author ILIKE ?", "%#{query}%", "%#{query}%")
            .recent
            .limit(limit)
            .offset((page - 1) * limit)
            .as_json(include: :reviews)
      end
    end

    # Finds books that contain the specified subject
    #
    # @param subject [String] The subject to search for
    # @return [ActiveRecord::Relation] Books containing the subject, newest first
    # @example
    #   BookService.books_by_subject("Fiction")    # All fiction books
    #   BookService.books_by_subject("Science")    # All science books
    def books_by_subject(subject)
      Book.includes(:reviews).by_subject(subject: subject).recent
    end

    # Finds books that contain the specified language
    #
    # @param language [String] The language to search for
    # @return [ActiveRecord::Relation] Books containing the language, newest first
    # @example
    #   BookService.books_by_language("English")   # All English books
    #   BookService.books_by_language("Spanish")   # All Spanish books
    def books_by_language(language)
      Book.includes(:reviews).by_language(language: language).recent
    end

    # Finds books by author name using case-insensitive partial matching
    #
    # @param author [String] The author name to search for
    # @return [ActiveRecord::Relation] Books by matching authors, newest first
    # @example
    #   BookService.books_by_author("Tolkien")     # All books by Tolkien
    #   BookService.books_by_author("J.R.R.")      # All books by J.R.R. Tolkien
    def books_by_author(author)
      Book.includes(:reviews).by_author(author_name: author).recent
    end

    # @!endgroup

    # @!group Rating and Popularity Operations

    # Finds books with high average ratings
    #
    # Uses an optimized subquery approach for better performance compared to
    # direct joins with grouping.
    #
    # @param min_score [Float] Minimum average rating threshold (default: Book::HIGHLY_RATED_THRESHOLD)
    # @return [ActiveRecord::Relation] Books with average rating >= min_score
    # @example
    #   BookService.highly_rated_books                    # Books with rating >= 4.0
    #   BookService.highly_rated_books(min_score: 3.5)    # Books with rating >= 3.5
    def highly_rated_books(min_score: Book::HIGHLY_RATED_THRESHOLD)
      # Use subquery for better performance - single query instead of two
      Book.includes(:reviews)
          .where(id: Book.highly_rated(min_score: min_score).select(:id))
    end

    # Finds books with high average ratings with caching
    #
    # @param limit [Integer] Maximum number of books to return (default: 10)
    # @param min_score [Float] Minimum average rating threshold (default: Book::HIGHLY_RATED_THRESHOLD)
    # @return [Array<Hash>] Cached highly rated books as JSON
    # @example
    #   BookService.cached_highly_rated_books(limit: 5)   # Top 5 highly rated books (cached)
    def cached_highly_rated_books(limit: 10, min_score: Book::HIGHLY_RATED_THRESHOLD)
      cache_key = CacheKeys::Book.highly_rated(limit: limit)

      CacheService.fetch(cache_key, expires_in: 1.hour) do
        Book.includes(:reviews)
            .where(id: Book.highly_rated(min_score: min_score).select(:id))
            .limit(limit)
            .as_json(include: :reviews)
      end
    end

    # Finds the most recently added books
    #
    # @param limit [Integer] Maximum number of books to return (default: Book::DEFAULT_RECENT_LIMIT)
    # @return [ActiveRecord::Relation] Most recently created books with reviews
    # @example
    #   BookService.recent_books                     # 10 most recent books
    #   BookService.recent_books(limit: 5)          # 5 most recent books
    def recent_books(limit: Book::DEFAULT_RECENT_LIMIT)
      Book.includes(:reviews).recent(limit: limit)
    end

    # Finds the most recently added books with caching
    #
    # @param limit [Integer] Maximum number of books to return (default: 10)
    # @return [Array<Hash>] Cached recent books as JSON
    # @example
    #   BookService.cached_recent_books(limit: 5)    # 5 most recent books (cached)
    def cached_recent_books(limit: 10)
      cache_key = CacheKeys::Book.recent(limit: limit)

      CacheService.fetch(cache_key, expires_in: 30.minutes) do
        Book.includes(:reviews)
            .recent(limit: limit)
            .as_json(include: :reviews)
      end
    end

    # @!endgroup

    # @!group Statistics and Analytics

    # Provides comprehensive statistics about books and reviews
    #
    # @return [Hash] A hash containing:
    #   - :total_books [Integer] - Total number of books in the system
    #   - :total_reviews [Integer] - Total number of reviews in the system
    #   - :average_rating [Float, nil] - Overall average rating across all reviews
    #   - :books_with_reviews [Integer] - Number of books that have been reviewed
    #   - :books_without_reviews [Integer] - Number of books without reviews
    # @example
    #   BookService.book_stats
    #   # => {
    #   #      total_books: 150,
    #   #      total_reviews: 320,
    #   #      average_rating: 3.8,
    #   #      books_with_reviews: 120,
    #   #      books_without_reviews: 30
    #   #    }
    def book_stats
      {
        total_books: Book.count,
        total_reviews: Review.count,
        average_rating: Review.average(:score)&.round(2),
        books_with_reviews: Book.with_reviews.count,
        books_without_reviews: Book.without_reviews.count
      }
    end

    # @!endgroup

    # @!group Cache Management

    # Invalidates cache for a specific book
    #
    # @param book_id [Integer] The book ID to invalidate cache for
    # @return [Integer] Number of cache keys deleted
    # @example
    #   BookService.invalidate_book_cache(123)    # Clear all cache for book 123
    def invalidate_book_cache(book_id)
      # Clear specific book cache using pattern
      pattern = CacheKeys::Book.pattern_for_book(book_id)
      keys = CacheService.keys(pattern)
      keys.any? ? CacheService.delete(keys) : 0
    end

    # Invalidates all book-related cache
    #
    # @return [Integer] Number of cache keys deleted
    # @example
    #   BookService.invalidate_all_books_cache    # Clear all book cache
    def invalidate_all_books_cache
      CacheKeys::Book.clear_all
    end

    # Invalidates search cache
    #
    # @return [Integer] Number of cache keys deleted
    # @example
    #   BookService.invalidate_search_cache       # Clear all search cache
    def invalidate_search_cache
      CacheKeys::Book.clear_search
    end

    # Invalidates statistics cache
    #
    # @return [Integer] Number of cache keys deleted
    # @example
    #   BookService.invalidate_stats_cache        # Clear all stats cache
    def invalidate_stats_cache
      # Note: Stats cache is not implemented in new structure yet
      # This method is kept for backward compatibility
      0
    end

    # Invalidates highly rated books cache
    #
    # @return [Integer] Number of cache keys deleted
    # @example
    #   BookService.invalidate_highly_rated_cache # Clear highly rated books cache
    def invalidate_highly_rated_cache
      # Clear highly rated cache using pattern
      pattern = "book_review:book:highly_rated:*"
      keys = CacheService.keys(pattern)
      keys.any? ? CacheService.delete(keys) : 0
    end

    # Invalidates recent books cache
    #
    # @return [Integer] Number of cache keys deleted
    # @example
    #   BookService.invalidate_recent_cache       # Clear recent books cache
    def invalidate_recent_cache
      # Clear recent cache using pattern
      pattern = "book_review:book:recent:*"
      keys = CacheService.keys(pattern)
      keys.any? ? CacheService.delete(keys) : 0
    end

    # Invalidates all cache (use with caution!)
    #
    # @return [Integer] Number of cache keys deleted
    # @example
    #   BookService.invalidate_all_cache          # Clear all cache
    def invalidate_all_cache
      # Clear all cache using pattern
      pattern = "book_review:*"
      keys = CacheService.keys(pattern)
      keys.any? ? CacheService.delete(keys) : 0
    end

    # @!endgroup
  end
end
