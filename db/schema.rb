# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2025_09_10_125649) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "books", force: :cascade do |t|
    t.string "title"
    t.text "subjects", default: [], array: true
    t.text "languages", default: [], array: true
    t.string "author"
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "author" ], name: "index_books_on_author"
    t.index [ "created_at" ], name: "index_books_on_created_at"
    t.index [ "languages" ], name: "index_books_on_languages_gin", using: :gin
    t.index [ "subjects" ], name: "index_books_on_subjects_gin", using: :gin
    t.index [ "title", "author" ], name: "index_books_on_title_and_author"
    t.index [ "title" ], name: "index_books_on_title"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "title"
    t.text "description"
    t.integer "score"
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "book_id", "created_at" ], name: "index_reviews_on_book_id_and_created_at"
    t.index [ "book_id", "score" ], name: "index_reviews_on_book_id_and_score"
    t.index [ "book_id" ], name: "index_reviews_on_book_id"
    t.index [ "created_at" ], name: "index_reviews_on_created_at"
    t.index [ "score" ], name: "index_reviews_on_score"
  end

  add_foreign_key "reviews", "books"
end
