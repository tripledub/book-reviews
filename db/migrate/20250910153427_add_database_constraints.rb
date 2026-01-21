class AddDatabaseConstraints < ActiveRecord::Migration[8.0]
  def change
    # Books table constraints

    # 1. NOT NULL constraints for required fields
    change_column_null :books, :title, false
    change_column_null :books, :author, false

    # 2. CHECK constraint for array fields (ensure they're not empty when provided)
    # This prevents empty strings in arrays
    execute <<-SQL
      ALTER TABLE books#{' '}
      ADD CONSTRAINT books_subjects_not_empty#{' '}
      CHECK (array_length(subjects, 1) IS NULL OR array_length(subjects, 1) > 0)
    SQL

    execute <<-SQL
      ALTER TABLE books#{' '}
      ADD CONSTRAINT books_languages_not_empty#{' '}
      CHECK (array_length(languages, 1) IS NULL OR array_length(languages, 1) > 0)
    SQL

    # 3. CHECK constraint for image URL format (basic validation)
    execute <<-SQL
      ALTER TABLE books#{' '}
      ADD CONSTRAINT books_image_url_format#{' '}
      CHECK (image IS NULL OR image ~ '^https?://')
    SQL

    # Reviews table constraints

    # 4. NOT NULL constraints for required fields
    change_column_null :reviews, :title, false
    change_column_null :reviews, :description, false
    change_column_null :reviews, :score, false

    # 5. CHECK constraint for score range (1-5)
    execute <<-SQL
      ALTER TABLE reviews#{' '}
      ADD CONSTRAINT reviews_score_range#{' '}
      CHECK (score >= 1 AND score <= 5)
    SQL

    # 6. CHECK constraint for text length (prevent empty strings)
    execute <<-SQL
      ALTER TABLE reviews#{' '}
      ADD CONSTRAINT reviews_title_not_empty#{' '}
      CHECK (length(trim(title)) > 0)
    SQL

    execute <<-SQL
      ALTER TABLE reviews#{' '}
      ADD CONSTRAINT reviews_description_not_empty#{' '}
      CHECK (length(trim(description)) > 0)
    SQL
  end

  def down
    # Remove constraints in reverse order

    # Reviews table
    execute "ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_description_not_empty"
    execute "ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_title_not_empty"
    execute "ALTER TABLE reviews DROP CONSTRAINT IF EXISTS reviews_score_range"

    change_column_null :reviews, :score, true
    change_column_null :reviews, :description, true
    change_column_null :reviews, :title, true

    # Books table
    execute "ALTER TABLE books DROP CONSTRAINT IF EXISTS books_image_url_format"
    execute "ALTER TABLE books DROP CONSTRAINT IF EXISTS books_languages_not_empty"
    execute "ALTER TABLE books DROP CONSTRAINT IF EXISTS books_subjects_not_empty"

    change_column_null :books, :author, true
    change_column_null :books, :title, true
  end
end
