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

    # Finds a specific book by ID with its associated reviews
    #
    # @param id [Integer, String] The book ID to find
    # @return [Book] The book with eager-loaded reviews
    # @raise [ActiveRecord::RecordNotFound] If book with given ID doesn't exist
    # @example
    #   BookService.find_book(1)              # Find book with ID 1
    #   BookService.find_book("123")          # Find book with ID "123"
    def find_book(id)
      Book.includes(:reviews).find(id)
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
  end
end
