class Book < ApplicationRecord
  # Constants for rating thresholds
  HIGHLY_RATED_THRESHOLD = 4.0
  DEFAULT_RECENT_LIMIT = 10

  has_many :reviews, dependent: :destroy

  validates :title, presence: true
  validates :author, presence: true

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

  # Scopes for common queries
  scope :highly_rated, ->(min_score = HIGHLY_RATED_THRESHOLD) {
    joins(:reviews)
      .group("books.id")
      .having("AVG(reviews.score) >= ?", min_score)
  }

  scope :recent, ->(limit = DEFAULT_RECENT_LIMIT) {
    order(created_at: :desc).limit(limit)
  }

  scope :by_subject, ->(subject) {
    where("subjects @> ARRAY[?]", subject)
  }

  scope :by_language, ->(language) {
    where("languages @> ARRAY[?]", language)
  }

  scope :by_author, ->(author_name) {
    where("author ILIKE ?", "%#{author_name}%")
  }

  scope :with_reviews, -> {
    joins(:reviews).distinct
  }

  scope :without_reviews, -> {
    left_joins(:reviews).where(reviews: { id: nil })
  }
end
