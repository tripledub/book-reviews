class FixArrayConstraints < ActiveRecord::Migration[8.0]
  def change
    # Drop the existing incorrect constraints
    execute "ALTER TABLE books DROP CONSTRAINT IF EXISTS books_subjects_not_empty"
    execute "ALTER TABLE books DROP CONSTRAINT IF EXISTS books_languages_not_empty"

    # Add corrected constraints that prevent empty arrays
    # array_length returns 0 for empty arrays, NULL for NULL arrays
    execute <<-SQL
      ALTER TABLE books#{' '}
      ADD CONSTRAINT books_subjects_not_empty#{' '}
      CHECK (subjects IS NULL OR array_length(subjects, 1) > 0)
    SQL

    execute <<-SQL
      ALTER TABLE books#{' '}
      ADD CONSTRAINT books_languages_not_empty#{' '}
      CHECK (languages IS NULL OR array_length(languages, 1) > 0)
    SQL
  end

  def down
    execute "ALTER TABLE books DROP CONSTRAINT IF EXISTS books_languages_not_empty"
    execute "ALTER TABLE books DROP CONSTRAINT IF EXISTS books_subjects_not_empty"

    # Restore the original (incorrect) constraints
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
  end
end
