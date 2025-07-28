class ChangeSubjectsAndLanguagesToArrayInBooks < ActiveRecord::Migration[7.1]
  def change
    change_column :books, :subjects, :text, array: true, default: [], using: 'ARRAY[subjects]'
    change_column :books, :languages, :text, array: true, default: [], using: 'ARRAY[languages]'
  end
end
