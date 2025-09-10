module RatingStatistics
  extend ActiveSupport::Concern

  # Computed attributes
  def average_rating
    return 0.0 if reviews.empty?
    reviews.average(:score).round(2)
  end

  def review_count
    reviews.count
  end

  def has_reviews?
    reviews.exists?
  end

  # Advanced rating statistics
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

  def rating_distribution
    return {} unless has_reviews?

    distribution = reviews.group(:score).count
    # Ensure all scores 1-5 are represented
    (1..5).each { |score| distribution[score] ||= 0 }
    distribution
  end

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

  private

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
end
