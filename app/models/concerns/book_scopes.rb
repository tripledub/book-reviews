module BookScopes
  extend ActiveSupport::Concern

  included do
    # Constants for rating thresholds
    HIGHLY_RATED_THRESHOLD = 4.0
    DEFAULT_RECENT_LIMIT = 10
  end

  class_methods do
    # Basic scopes for common queries
    def highly_rated(min_score = HIGHLY_RATED_THRESHOLD)
      joins(:reviews)
        .group("books.id")
        .having("AVG(reviews.score) >= ?", min_score)
    end

    def recent(limit = DEFAULT_RECENT_LIMIT)
      order(created_at: :desc).limit(limit)
    end

    def by_subject(subject)
      where("subjects @> ARRAY[?]", subject)
    end

    def by_language(language)
      where("languages @> ARRAY[?]", language)
    end

    def by_author(author_name)
      where("author ILIKE ?", "%#{author_name}%")
    end

    def with_reviews
      joins(:reviews).distinct
    end

    def without_reviews
      left_joins(:reviews).where(reviews: { id: nil })
    end

    # Advanced scopes
    def popular_books(limit = 10)
      joins(:reviews)
        .group("books.id, books.title, books.author, books.subjects, books.languages, books.image, books.created_at, books.updated_at")
        .order("COUNT(reviews.id) DESC")
        .limit(limit)
    end

    def by_rating_range(min_score, max_score)
      joins(:reviews)
        .group("books.id, books.title, books.author, books.subjects, books.languages, books.image, books.created_at, books.updated_at")
        .having("AVG(reviews.score) >= ? AND AVG(reviews.score) <= ?", min_score, max_score)
    end

    def trending_books(days = 30, min_reviews = 2)
      joins(:reviews)
        .where(reviews: { created_at: days.days.ago.. })
        .group("books.id, books.title, books.author, books.subjects, books.languages, books.image, books.created_at, books.updated_at")
        .having("COUNT(reviews.id) >= ? AND AVG(reviews.score) >= ?", min_reviews, HIGHLY_RATED_THRESHOLD)
        .order("AVG(reviews.score) DESC")
    end
  end
end
