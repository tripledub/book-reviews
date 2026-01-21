# @!parse
#   extend ActiveSupport::Concern
#
# Provides comprehensive rating statistics and computed attributes for models with reviews.
# This concern adds methods to calculate averages, distributions, percentiles, and other
# rating-related metrics that are commonly needed for book review applications.
#
# @example Basic usage in a Book model
#   class Book < ApplicationRecord
#     include RatingStatistics
#     has_many :reviews
#   end
#
#   book = Book.find(1)
#   book.average_rating    # => 4.2
#   book.rating_summary    # => { average: 4.2, count: 15, ... }
#   book.rating_percentile # => 85.5
#
# @since 1.0.0
module RatingStatistics
  extend ActiveSupport::Concern

  # @!group Computed Attributes

  # Calculates the average rating score from all reviews
  #
  # @return [Float] The average score rounded to 2 decimal places, or 0.0 if no reviews
  # @example
  #   book.average_rating # => 4.25
  def average_rating
    return 0.0 if reviews.empty?
    reviews.average(:score).round(2)
  end

  # Counts the total number of reviews for this record
  #
  # @return [Integer] The number of reviews, or 0 if none exist
  # @example
  #   book.review_count # => 12
  def review_count
    reviews.count
  end

  # Checks if this record has any reviews
  #
  # @return [Boolean] true if reviews exist, false otherwise
  # @example
  #   book.has_reviews? # => true
  def has_reviews?
    reviews.exists?
  end

  # @!endgroup

  # @!group Advanced Rating Statistics

  # Provides a comprehensive summary of all rating statistics
  #
  # @return [Hash] A hash containing:
  #   - :average [Float] - Average rating score
  #   - :count [Integer] - Total number of reviews
  #   - :distribution [Hash] - Count of reviews for each score (1-5)
  #   - :highest [Integer, nil] - Highest score received
  #   - :lowest [Integer, nil] - Lowest score received
  #   - :median [Float] - Median rating score
  # @return [Hash] Default summary with zero values if no reviews exist
  # @example
  #   book.rating_summary
  #   # => {
  #   #      average: 4.2,
  #   #      count: 15,
  #   #      distribution: { 1 => 0, 2 => 1, 3 => 2, 4 => 5, 5 => 7 },
  #   #      highest: 5,
  #   #      lowest: 2,
  #   #      median: 4.0
  #   #    }
  def rating_summary
    return default_rating_summary unless has_reviews?

    {
      average: average_rating,
      count: review_count,
      distribution: rating_distribution,
      highest: reviews.maximum(:score),
      lowest: reviews.minimum(:score),
      median: calculate_median_rating
    }
  end

  # Calculates the distribution of review scores
  #
  # @return [Hash] A hash with score (1-5) as keys and count as values
  # @return [Hash] Empty hash if no reviews exist
  # @example
  #   book.rating_distribution
  #   # => { 1 => 0, 2 => 1, 3 => 2, 4 => 5, 5 => 7 }
  def rating_distribution
    return {} unless has_reviews?

    distribution = reviews.group(:score).count
    # Ensure all scores 1-5 are represented
    (1..5).each { |score| distribution[score] ||= 0 }
    distribution
  end

  # Calculates what percentile this record's rating falls into compared to all rated records
  #
  # This method compares the current record's average rating against all other records
  # that have reviews, returning the percentage of records that have lower ratings.
  #
  # @return [Float] The percentile (0.0-100.0), or 0.0 if no reviews exist
  # @example
  #   book.rating_percentile # => 85.5  # This book is better than 85.5% of all books
  def rating_percentile
    return 0.0 unless has_reviews?

    # Calculate what percentile this book's rating is compared to all books
    better_books_count = self.class.joins(:reviews)
                            .group("books.id")
                            .having("AVG(reviews.score) > ?", average_rating)
                            .count
                            .size

    total_rated_books = self.class.joins(:reviews).distinct.count
    return 0.0 if total_rated_books.zero?

    (better_books_count.to_f / total_rated_books * 100).round(1)
  end

  # @!endgroup

  private

  # @!group Private Helper Methods

  # Returns a default rating summary for records with no reviews
  #
  # @return [Hash] A hash with zero/nil values for all rating statistics
  # @private
  def default_rating_summary
    {
      average: 0.0,
      count: 0,
      distribution: {},
      highest: nil,
      lowest: nil,
      median: 0.0
    }
  end

  # Calculates the median rating score from all reviews
  #
  # For odd numbers of reviews, returns the middle score.
  # For even numbers of reviews, returns the average of the two middle scores.
  #
  # @return [Float] The median score, or 0.0 if no reviews exist
  # @private
  def calculate_median_rating
    scores = reviews.pluck(:score).sort
    return 0.0 if scores.empty?

    mid = scores.length / 2
    if scores.length.odd?
      scores[mid]
    else
      (scores[mid - 1] + scores[mid]) / 2.0
    end
  end

  # @!endgroup
end
