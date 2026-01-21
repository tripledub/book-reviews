class AddIndexesForPerformance < ActiveRecord::Migration[8.0]
  def change
    # Books table indexes

    # 1. Index on title for search functionality (ILIKE queries)
    # This supports the search endpoint: WHERE title ILIKE '%query%'
    add_index :books, :title, name: 'index_books_on_title'

    # 2. Index on author for search functionality (ILIKE queries)
    # This supports the search endpoint: WHERE author ILIKE '%query%'
    add_index :books, :author, name: 'index_books_on_author'

    # 3. Composite index for title + author searches
    # This can be used for more complex search queries
    add_index :books, [ :title, :author ], name: 'index_books_on_title_and_author'

    # 4. Index on created_at for ordering (newest books first)
    # Useful for pagination and ordering by creation date
    add_index :books, :created_at, name: 'index_books_on_created_at'

    # 5. GIN index for array columns (subjects and languages)
    # PostgreSQL-specific: allows efficient querying of array elements
    add_index :books, :subjects, using: :gin, name: 'index_books_on_subjects_gin'
    add_index :books, :languages, using: :gin, name: 'index_books_on_languages_gin'

    # Reviews table indexes

    # 6. Index on book_id (already exists from foreign key, but let's be explicit)
    # This is crucial for the includes(:reviews) queries in BooksController
    add_index :reviews, :book_id, name: 'index_reviews_on_book_id' unless index_exists?(:reviews, :book_id)

    # 7. Index on score for filtering and aggregations
    # Useful for queries like: WHERE score >= 4, AVG(score), etc.
    add_index :reviews, :score, name: 'index_reviews_on_score'

    # 8. Composite index on book_id + score for efficient book rating calculations
    # This supports queries like: SELECT AVG(score) WHERE book_id = ?
    add_index :reviews, [ :book_id, :score ], name: 'index_reviews_on_book_id_and_score'

    # 9. Index on created_at for ordering reviews
    # Useful for showing newest reviews first
    add_index :reviews, :created_at, name: 'index_reviews_on_created_at'

    # 10. Composite index for book_id + created_at
    # Efficient for queries like: reviews for a book ordered by date
    add_index :reviews, [ :book_id, :created_at ], name: 'index_reviews_on_book_id_and_created_at'
  end
end
