class Review < ApplicationRecord
  # Constants for score ranges
  MIN_SCORE = 1
  MAX_SCORE = 5
  HIGH_RATED_THRESHOLD = 4
  LOW_RATED_THRESHOLD = 2

  belongs_to :book

  validates :title, presence: true
  validates :description, presence: true
  validates :score, presence: true, inclusion: { in: MIN_SCORE..MAX_SCORE }

  # Cache invalidation callbacks
  after_create :invalidate_cache_after_create
  after_update :invalidate_cache_after_update
  after_destroy :invalidate_cache_after_destroy

  private

  # Invalidate cache after review creation
  def invalidate_cache_after_create
    invalidate_book_related_cache
  end

  # Invalidate cache after review update
  def invalidate_cache_after_update
    invalidate_book_related_cache
  end

  # Invalidate cache after review destruction
  def invalidate_cache_after_destroy
    invalidate_book_related_cache
  end

  # Invalidate all cache related to the book
  def invalidate_book_related_cache
    BookService.invalidate_book_cache(book_id)
    BookService.invalidate_all_books_cache
    BookService.invalidate_highly_rated_cache
    BookService.invalidate_stats_cache
  end
end
