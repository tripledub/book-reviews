class ReviewService
  class << self
    # Create a new review
    def create_review(attributes)
      review = Review.new(attributes)
      review.save!
      review.reload
    end

    # Get all reviews for a specific book
    def reviews_for_book(book_id)
      Review.includes(:book)
            .where(book_id: book_id)
            .order(created_at: :desc)
    end

    # Get reviews by score range
    def reviews_by_score(min_score, max_score = 5)
      Review.includes(:book)
            .where(score: min_score..max_score)
            .order(created_at: :desc)
    end

    # Get high-rated reviews (score >= 4)
    def high_rated_reviews
      reviews_by_score(4)
    end

    # Get low-rated reviews (score <= 2)
    def low_rated_reviews
      reviews_by_score(1, 2)
    end

    # Get recent reviews
    def recent_reviews(limit = 10)
      Review.includes(:book)
            .order(created_at: :desc)
            .limit(limit)
    end

    # Calculate average rating for a book
    def average_rating_for_book(book_id)
      Review.where(book_id: book_id).average(:score)&.round(2)
    end

    # Get review statistics
    def review_stats
      {
        total_reviews: Review.count,
        average_rating: Review.average(:score)&.round(2),
        high_rated_count: Review.where("score >= 4").count,
        low_rated_count: Review.where("score <= 2").count,
        rating_distribution: Review.group(:score).count
      }
    end

    # Get reviews with pagination (using limit/offset)
    def paginated_reviews(page = 1, per_page = 20)
      offset = (page - 1) * per_page
      Review.includes(:book)
            .order(created_at: :desc)
            .limit(per_page)
            .offset(offset)
    end

    # Search reviews by title or description
    def search_reviews(query)
      return { success: false, error: "Search query is required" } if query.blank?

      reviews = Review.includes(:book)
                      .where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
                      .order(created_at: :desc)

      { success: true, reviews: reviews }
    end

    # Get reviews for multiple books
    def reviews_for_books(book_ids)
      Review.includes(:book)
            .where(book_id: book_ids)
            .order(created_at: :desc)
    end
  end
end
