class CreateBooks < ActiveRecord::Migration[8.0]
  def change
    create_table :books do |t|
      t.string :title
      t.string :subjects
      t.string :languages
      t.string :author
      t.string :image

      t.timestamps
    end
  end
end
