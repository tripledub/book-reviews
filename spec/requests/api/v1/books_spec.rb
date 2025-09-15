require 'rails_helper'

RSpec.describe "Api::V1::Books", type: :request do
  let!(:book) { Book.create!(title: Faker::Book.title, author: Faker::Book.author, subjects: [ Faker::Book.genre ], languages: [ "en" ], image: Faker::Internet.url) }
  let!(:review) { Review.create!(book: book, title: "Great Book", description: "Amazing read", score: 5) }

  describe "GET /api/v1/books" do
    it "returns http success and books with reviews" do
      get "/api/v1/books"
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("books")
      expect(json_response).to have_key("pagy")
      expect(json_response["books"]).to be_an(Array)
      expect(json_response["books"].first["title"]).to eq(book.title)
      expect(json_response["books"].first["reviews"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/books" do
    it "creates a new book and returns http created" do
      book_title = Faker::Book.title
      book_author = Faker::Book.author
      book_params = {
        book: {
          title: book_title,
          author: book_author,
          subjects: [ Faker::Book.genre ],
          languages: [ "en" ],
          image: Faker::Internet.url
        }
      }

      post "/api/v1/books", params: book_params
      expect(response).to have_http_status(:created)

      json_response = JSON.parse(response.body)
      expect(json_response["title"]).to eq(book_title)
      expect(json_response["author"]).to eq(book_author)
    end

    it "returns unprocessable entity for invalid params" do
      post "/api/v1/books", params: { book: { title: "" } }
      expect(response).to have_http_status(:unprocessable_content)
    end
  end

  describe "GET /api/v1/books/:id" do
    it "returns http success and book with reviews" do
      get "/api/v1/books/#{book.id}"
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["title"]).to eq(book.title)
      expect(json_response["reviews"]).to be_an(Array)
      expect(json_response["reviews"].first["title"]).to eq("Great Book")
    end

    it "returns not found for invalid id" do
      get "/api/v1/books/999999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/books/search" do
    it "returns http success for valid search query" do
      get "/api/v1/books/search", params: { q: book.title.split.first }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("books")
      expect(json_response["books"]).to be_an(Array)
      expect(json_response["books"].first["title"]).to eq(book.title)
    end

    it "returns bad request for missing query parameter" do
      get "/api/v1/books/search"
      expect(response).to have_http_status(:bad_request)
    end

    it "returns empty array for no matches" do
      get "/api/v1/books/search", params: { q: "Nonexistent" }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("books")
      expect(json_response["books"]).to eq([])
    end
  end
end
