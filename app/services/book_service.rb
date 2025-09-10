class BookService
  class << self
    # Get all books with their reviews
    def all_books
      Book.includes(:reviews).recent
    end

    # Find a specific book by ID with reviews
    def find_book(id)
      Book.includes(:reviews).find(id)
    end

    # Create a new book
    def create_book(attributes)
      book = Book.new(attributes)
      book.save!
      book.reload
    end

    # Search books by title or author
    def search_books(query)
      raise ArgumentError, "Search query is required" if query.blank?

      Book.includes(:reviews)
          .where("title ILIKE ? OR author ILIKE ?", "%#{query}%", "%#{query}%")
          .recent
    end

    # Get books by subject
    def books_by_subject(subject)
      Book.includes(:reviews).by_subject(subject).recent
    end

    # Get books by language
    def books_by_language(language)
      Book.includes(:reviews).by_language(language).recent
    end

    # Get books by author
    def books_by_author(author)
      Book.includes(:reviews).by_author(author).recent
    end

    # Get books with high ratings (average score >= threshold)
    def highly_rated_books(min_score = Book::HIGHLY_RATED_THRESHOLD)
      # Use subquery for better performance - single query instead of two
      Book.includes(:reviews)
          .where(id: Book.highly_rated(min_score).select(:id))
    end

    # Get recently added books
    def recent_books(limit = Book::DEFAULT_RECENT_LIMIT)
      Book.includes(:reviews).recent(limit)
    end

    # Get book statistics
    def book_stats
      {
        total_books: Book.count,
        total_reviews: Review.count,
        average_rating: Review.average(:score)&.round(2),
        books_with_reviews: Book.with_reviews.count,
        books_without_reviews: Book.without_reviews.count
      }
    end
  end
end
