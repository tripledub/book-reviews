# Service object for managing review-related operations and queries.
# Provides a clean interface for controllers to interact with reviews without
# exposing complex ActiveRecord queries and business logic.
#
# @example Basic usage
#   ReviewService.create_review(book_id: 1, title: "Great!", score: 5)
#   ReviewService.reviews_for_book(1)        # Get all reviews for book 1
#   ReviewService.high_rated_reviews         # Get all 4-5 star reviews
#   ReviewService.search_reviews("amazing")  # Search review content
#
# @since 1.0.0
class ReviewService
  class << self
    # @!group Basic Operations

    # Creates a new review with the provided attributes
    #
    # @param attributes [Hash] The attributes for the new review
    # @option attributes [Integer] :book_id The ID of the book being reviewed (required)
    # @option attributes [String] :title The review title (required)
    # @option attributes [String] :description The review description (required)
    # @option attributes [Integer] :score The rating score 1-5 (required)
    # @return [Review] The created review (reloaded from database)
    # @raise [ActiveRecord::RecordInvalid] If validation fails
    # @example
    #   ReviewService.create_review(
    #     book_id: 1,
    #     title: "Amazing book!",
    #     description: "Couldn't put it down",
    #     score: 5
    #   )
    def create_review(attributes)
      review = Review.new(attributes)
      review.save!
      review.reload
    end

    # @!endgroup

    # @!group Query Operations

    # Retrieves all reviews for a specific book
    #
    # @param book_id [Integer, String] The ID of the book
    # @return [ActiveRecord::Relation] Reviews for the book, newest first
    # @example
    #   ReviewService.reviews_for_book(1)     # All reviews for book 1
    #   ReviewService.reviews_for_book("123") # All reviews for book "123"
    def reviews_for_book(book_id)
      Review.includes(:book)
            .where(book_id: book_id)
            .order(created_at: :desc)
    end

    # Finds reviews within a specific score range
    #
    # @param min_score [Integer] Minimum score (inclusive)
    # @param max_score [Integer] Maximum score (inclusive, default: 5)
    # @return [ActiveRecord::Relation] Reviews within the score range, newest first
    # @example
    #   ReviewService.reviews_by_score(min_score: 4)              # Reviews with score 4-5
    #   ReviewService.reviews_by_score(min_score: 1, max_score: 3) # Reviews with score 1-3
    #   ReviewService.reviews_by_score(min_score: 5, max_score: 5) # Only 5-star reviews
    def reviews_by_score(min_score:, max_score: 5)
      Review.includes(:book)
            .where(score: min_score..max_score)
            .order(created_at: :desc)
    end

    # Finds high-rated reviews (score >= 4)
    #
    # @return [ActiveRecord::Relation] High-rated reviews, newest first
    # @example
    #   ReviewService.high_rated_reviews            # All 4-5 star reviews
    def high_rated_reviews
      reviews_by_score(min_score: 4)
    end

    # Finds low-rated reviews (score <= 2)
    #
    # @return [ActiveRecord::Relation] Low-rated reviews, newest first
    # @example
    #   ReviewService.low_rated_reviews             # All 1-2 star reviews
    def low_rated_reviews
      reviews_by_score(min_score: 1, max_score: 2)
    end

    # Finds the most recently created reviews
    #
    # @param limit [Integer] Maximum number of reviews to return (default: 10)
    # @return [ActiveRecord::Relation] Most recent reviews with books
    # @example
    #   ReviewService.recent_reviews                    # 10 most recent reviews
    #   ReviewService.recent_reviews(limit: 5)         # 5 most recent reviews
    def recent_reviews(limit: 10)
      Review.includes(:book)
            .order(created_at: :desc)
            .limit(limit)
    end

    # @!endgroup

    # @!group Statistics and Analytics

    # Calculates the average rating for a specific book
    #
    # @param book_id [Integer, String] The ID of the book
    # @return [Float, nil] The average rating rounded to 2 decimal places, or nil if no reviews
    # @example
    #   ReviewService.average_rating_for_book(1)    # => 4.25
    #   ReviewService.average_rating_for_book(999)  # => nil (no reviews)
    def average_rating_for_book(book_id)
      Review.where(book_id: book_id).average(:score)&.round(2)
    end

    # Provides comprehensive statistics about reviews
    #
    # @return [Hash] A hash containing:
    #   - :total_reviews [Integer] - Total number of reviews in the system
    #   - :average_rating [Float, nil] - Overall average rating across all reviews
    #   - :high_rated_count [Integer] - Number of reviews with score >= 4
    #   - :low_rated_count [Integer] - Number of reviews with score <= 2
    #   - :rating_distribution [Hash] - Count of reviews for each score (1-5)
    # @example
    #   ReviewService.review_stats
    #   # => {
    #   #      total_reviews: 150,
    #   #      average_rating: 3.8,
    #   #      high_rated_count: 90,
    #   #      low_rated_count: 20,
    #   #      rating_distribution: { 1 => 10, 2 => 10, 3 => 30, 4 => 50, 5 => 50 }
    #   #    }
    def review_stats
      {
        total_reviews: Review.count,
        average_rating: Review.average(:score)&.round(2),
        high_rated_count: Review.where("score >= 4").count,
        low_rated_count: Review.where("score <= 2").count,
        rating_distribution: Review.group(:score).count
      }
    end

    # @!endgroup

    # @!group Pagination and Search

    # Retrieves reviews for pagination (to be used with controller's pagy method)
    #
    # @return [ActiveRecord::Relation] Reviews ordered by creation date (newest first)
    # @example
    #   # In controller:
    #   @pagy, @reviews = pagy(ReviewService.paginated_reviews)
    def paginated_reviews
      Review.includes(:book).order(created_at: :desc)
    end

    # Searches reviews by title or description using case-insensitive partial matching
    #
    # @param query [String] The search term to match against title or description
    # @return [Hash] A hash containing:
    #   - :success [Boolean] - Whether the search was successful
    #   - :reviews [ActiveRecord::Relation] - Matching reviews (if successful)
    #   - :error [String] - Error message (if unsuccessful)
    # @example
    #   ReviewService.search_reviews(query: "amazing")     # Find reviews with "amazing"
    #   ReviewService.search_reviews(query: "")            # => { success: false, error: "..." }
    def search_reviews(query:)
      return { success: false, error: "Search query is required" } if query.blank?

      reviews = Review.includes(:book)
                      .where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
                      .order(created_at: :desc)

      { success: true, reviews: reviews }
    end

    # @!endgroup

    # @!group Batch Operations

    # Retrieves reviews for multiple books
    #
    # @param book_ids [Array<Integer>, Array<String>] Array of book IDs
    # @return [ActiveRecord::Relation] Reviews for the specified books, newest first
    # @example
    #   ReviewService.reviews_for_books([1, 2, 3])  # Reviews for books 1, 2, and 3
    #   ReviewService.reviews_for_books(["1", "2"]) # Reviews for books "1" and "2"
    def reviews_for_books(book_ids)
      Review.includes(:book)
            .where(book_id: book_ids)
            .order(created_at: :desc)
    end

    # @!endgroup
  end
end
