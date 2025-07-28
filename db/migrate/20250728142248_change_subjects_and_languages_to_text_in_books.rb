class ChangeSubjectsAndLanguagesToTextInBooks < ActiveRecord::Migration[7.1]
  def change
    change_column :books, :subjects, :text
    change_column :books, :languages, :text
  end
end
