class CreateReviews < ActiveRecord::Migration[8.0]
  def change
    create_table :reviews do |t|
      t.string :title
      t.text :description
      t.integer :score
      t.references :book, null: false, foreign_key: true

      t.timestamps
    end
  end
end
