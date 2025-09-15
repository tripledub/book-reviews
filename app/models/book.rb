class Book < ApplicationRecord
  include RatingStatistics
  include BookScopes

  has_many :reviews, dependent: :destroy

  validates :title, presence: true
  validates :author, presence: true

  # Cache invalidation callbacks
  after_create :invalidate_cache_after_create
  after_update :invalidate_cache_after_update
  after_destroy :invalidate_cache_after_destroy

  private

  # Invalidate cache after book creation
  def invalidate_cache_after_create
    BookService.invalidate_all_books_cache
    BookService.invalidate_recent_cache
    BookService.invalidate_highly_rated_cache
  end

  # Invalidate cache after book update
  def invalidate_cache_after_update
    BookService.invalidate_book_cache(id)
    BookService.invalidate_all_books_cache
    BookService.invalidate_search_cache
    BookService.invalidate_recent_cache
    BookService.invalidate_highly_rated_cache
  end

  # Invalidate cache after book destruction
  def invalidate_cache_after_destroy
    BookService.invalidate_book_cache(id)
    BookService.invalidate_all_books_cache
    BookService.invalidate_search_cache
    BookService.invalidate_recent_cache
    BookService.invalidate_highly_rated_cache
  end
end
