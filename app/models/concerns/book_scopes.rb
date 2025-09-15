# @!parse
#   extend ActiveSupport::Concern
#
# Provides comprehensive query scopes for models with reviews and metadata.
# This concern adds class methods for filtering, sorting, and finding records
# based on ratings, subjects, languages, authors, and other criteria.
#
# @example Basic usage in a Book model
#   class Book < ApplicationRecord
#     include BookScopes
#     has_many :reviews
#   end
#
#   Book.highly_rated                    # Books with average rating >= 4.0
#   Book.by_subject("Fiction")           # Books with "Fiction" in subjects
#   Book.popular_books(5)                # Top 5 most reviewed books
#   Book.trending_books(7, 3)            # Books trending in last 7 days
#
# @since 1.0.0
module BookScopes
  extend ActiveSupport::Concern

  included do
    # @!group Constants

    # Minimum average rating score to be considered "highly rated"
    # @return [Float] Default threshold of 4.0
    HIGHLY_RATED_THRESHOLD = 4.0

    # Default limit for recent records queries
    # @return [Integer] Default limit of 10 records
    DEFAULT_RECENT_LIMIT = 10

    # @!endgroup
  end

  class_methods do
    # @!group Basic Scopes

    # Finds records with average rating above the specified threshold
    #
    # @param min_score [Float] Minimum average rating (default: HIGHLY_RATED_THRESHOLD)
    # @return [ActiveRecord::Relation] Records with average rating >= min_score
    # @example
    #   Book.highly_rated                    # Books with rating >= 4.0
    #   Book.highly_rated(min_score: 3.5)    # Books with rating >= 3.5
    def highly_rated(min_score: HIGHLY_RATED_THRESHOLD)
      joins(:reviews)
        .group("books.id")
        .having("AVG(reviews.score) >= ?", min_score)
    end

    # Finds the most recently created records
    #
    # @param limit [Integer] Maximum number of records to return (default: DEFAULT_RECENT_LIMIT)
    # @return [ActiveRecord::Relation] Records ordered by creation date (newest first)
    # @example
    #   Book.recent                    # 10 most recent books
    #   Book.recent(limit: 5)          # 5 most recent books
    def recent(limit: DEFAULT_RECENT_LIMIT)
      order(created_at: :desc).limit(limit)
    end

    # Finds records that contain the specified subject
    #
    # Uses PostgreSQL array containment operator (@>) for efficient searching.
    #
    # @param subject [String] The subject to search for
    # @return [ActiveRecord::Relation] Records containing the subject
    # @example
    #   Book.by_subject(subject: "Fiction")     # Books with "Fiction" in subjects array
    #   Book.by_subject(subject: "Science")     # Books with "Science" in subjects array
    def by_subject(subject:)
      where("subjects @> ARRAY[?]", subject)
    end

    # Finds records that contain the specified language
    #
    # Uses PostgreSQL array containment operator (@>) for efficient searching.
    #
    # @param language [String] The language to search for
    # @return [ActiveRecord::Relation] Records containing the language
    # @example
    #   Book.by_language(language: "English")    # Books with "English" in languages array
    #   Book.by_language(language: "Spanish")    # Books with "Spanish" in languages array
    def by_language(language:)
      where("languages @> ARRAY[?]", language)
    end

    # Finds records by author name (case-insensitive partial match)
    #
    # @param author_name [String] The author name to search for
    # @return [ActiveRecord::Relation] Records with matching author names
    # @example
    #   Book.by_author(author_name: "Tolkien")      # Books by authors containing "Tolkien"
    #   Book.by_author(author_name: "J.R.R.")       # Books by authors containing "J.R.R."
    def by_author(author_name:)
      where("author ILIKE ?", "%#{author_name}%")
    end

    # Finds records that have at least one review
    #
    # @return [ActiveRecord::Relation] Records with associated reviews
    # @example
    #   Book.with_reviews              # All books that have been reviewed
    def with_reviews
      joins(:reviews).distinct
    end

    # Finds records that have no reviews
    #
    # @return [ActiveRecord::Relation] Records without any reviews
    # @example
    #   Book.without_reviews           # All books that haven't been reviewed yet
    def without_reviews
      left_joins(:reviews).where(reviews: { id: nil })
    end

    # @!endgroup

    # @!group Advanced Scopes

    # Finds the most popular records based on review count
    #
    # @param limit [Integer] Maximum number of records to return (default: 10)
    # @return [ActiveRecord::Relation] Records ordered by review count (most reviewed first)
    # @example
    #   Book.popular_books                 # Top 10 most reviewed books
    #   Book.popular_books(limit: 5)       # Top 5 most reviewed books
    def popular_books(limit: 10)
      joins(:reviews)
        .group("books.id, books.title, books.author, books.subjects, books.languages, books.image, books.created_at, books.updated_at")
        .order("COUNT(reviews.id) DESC")
        .limit(limit)
    end

    # Finds records with average rating within the specified range
    #
    # @param min_score [Float] Minimum average rating (inclusive)
    # @param max_score [Float] Maximum average rating (inclusive)
    # @return [ActiveRecord::Relation] Records with average rating in range
    # @example
    #   Book.by_rating_range(min_score: 3.0, max_score: 4.0) # Books with rating between 3.0 and 4.0
    #   Book.by_rating_range(min_score: 4.5, max_score: 5.0) # Books with rating between 4.5 and 5.0
    def by_rating_range(min_score:, max_score:)
      joins(:reviews)
        .group("books.id, books.title, books.author, books.subjects, books.languages, books.image, books.created_at, books.updated_at")
        .having("AVG(reviews.score) >= ? AND AVG(reviews.score) <= ?", min_score, max_score)
    end

    # Finds records that are currently trending based on recent reviews
    #
    # A record is considered "trending" if it has received multiple high-quality
    # reviews within the specified time period.
    #
    # @param days [Integer] Number of days to look back for trending (default: 30)
    # @param min_reviews [Integer] Minimum number of reviews required (default: 2)
    # @return [ActiveRecord::Relation] Trending records ordered by average rating
    # @example
    #   Book.trending_books                                    # Books trending in last 30 days
    #   Book.trending_books(days: 7, min_reviews: 3)          # Books trending in last 7 days with 3+ reviews
    #   Book.trending_books(days: 14, min_reviews: 5)         # Books trending in last 14 days with 5+ reviews
    def trending_books(days: 30, min_reviews: 2)
      joins(:reviews)
        .where(reviews: { created_at: days.days.ago.. })
        .group("books.id, books.title, books.author, books.subjects, books.languages, books.image, books.created_at, books.updated_at")
        .having("COUNT(reviews.id) >= ? AND AVG(reviews.score) >= ?", min_reviews, HIGHLY_RATED_THRESHOLD)
        .order("AVG(reviews.score) DESC")
    end

    # @!endgroup
  end
end
