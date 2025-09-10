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

ActiveRecord::Schema[8.0].define(version: 2025_09_10_153944) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "books", force: :cascade do |t|
    t.string "title", null: false
    t.text "subjects", default: [], array: true
    t.text "languages", default: [], array: true
    t.string "author", null: false
    t.string "image"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "author" ], name: "index_books_on_author"
    t.index [ "created_at" ], name: "index_books_on_created_at"
    t.index [ "languages" ], name: "index_books_on_languages_gin", using: :gin
    t.index [ "subjects" ], name: "index_books_on_subjects_gin", using: :gin
    t.index [ "title", "author" ], name: "index_books_on_title_and_author"
    t.index [ "title" ], name: "index_books_on_title"
    t.check_constraint "image IS NULL OR image::text ~ '^https?://'::text", name: "books_image_url_format"
    t.check_constraint "languages IS NULL OR array_length(languages, 1) > 0", name: "books_languages_not_empty"
    t.check_constraint "subjects IS NULL OR array_length(subjects, 1) > 0", name: "books_subjects_not_empty"
  end

  create_table "reviews", force: :cascade do |t|
    t.string "title", null: false
    t.text "description", null: false
    t.integer "score", null: false
    t.bigint "book_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index [ "book_id", "created_at" ], name: "index_reviews_on_book_id_and_created_at"
    t.index [ "book_id", "score" ], name: "index_reviews_on_book_id_and_score"
    t.index [ "book_id" ], name: "index_reviews_on_book_id"
    t.index [ "created_at" ], name: "index_reviews_on_created_at"
    t.index [ "score" ], name: "index_reviews_on_score"
    t.check_constraint "length(TRIM(BOTH FROM description)) > 0", name: "reviews_description_not_empty"
    t.check_constraint "length(TRIM(BOTH FROM title)) > 0", name: "reviews_title_not_empty"
    t.check_constraint "score >= 1 AND score <= 5", name: "reviews_score_range"
  end

  add_foreign_key "reviews", "books"
end
