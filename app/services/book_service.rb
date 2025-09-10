class BookService
  class << self
    # Get all books with their reviews
    def all_books
      Book.includes(:reviews).order(created_at: :desc)
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
      return { success: false, error: "Search query is required" } if query.blank?

      books = Book.includes(:reviews)
                  .where("title ILIKE ? OR author ILIKE ?", "%#{query}%", "%#{query}%")
                  .order(created_at: :desc)

      { success: true, books: books }
    end

    # Get books by subject
    def books_by_subject(subject)
      Book.includes(:reviews)
          .where("subjects @> ARRAY[?]", subject)
          .order(created_at: :desc)
    end

    # Get books by language
    def books_by_language(language)
      Book.includes(:reviews)
          .where("languages @> ARRAY[?]", language)
          .order(created_at: :desc)
    end

    # Get books by author
    def books_by_author(author)
      Book.includes(:reviews)
          .where("author ILIKE ?", "%#{author}%")
          .order(created_at: :desc)
    end

    # Get books with high ratings (average score >= 4)
    def highly_rated_books
      Book.joins(:reviews)
          .group("books.id, books.title, books.author, books.subjects, books.languages, books.image, books.created_at, books.updated_at")
          .having("AVG(reviews.score) >= ?", 4.0)
          .order("AVG(reviews.score) DESC")
    end

    # Get recently added books
    def recent_books(limit = 10)
      Book.includes(:reviews)
          .order(created_at: :desc)
          .limit(limit)
    end

    # Get book statistics
    def book_stats
      {
        total_books: Book.count,
        total_reviews: Review.count,
        average_rating: Review.average(:score)&.round(2),
        books_with_reviews: Book.joins(:reviews).distinct.count
      }
    end
  end
end
