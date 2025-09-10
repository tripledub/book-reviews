require 'rails_helper'

RSpec.describe "Api::V1::Books", type: :request do
  let!(:book) { Book.create!(title: "Test Book", author: "Test Author", subjects: [ "Fiction" ], languages: [ "en" ], image: "test.jpg") }
  let!(:review) { Review.create!(book: book, title: "Great Book", description: "Amazing read", score: 5) }

  describe "GET /api/v1/books" do
    it "returns http success and books with reviews" do
      get "/api/v1/books"
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.first["title"]).to eq("Test Book")
      expect(json_response.first["reviews"]).to be_an(Array)
    end
  end

  describe "POST /api/v1/books" do
    it "creates a new book and returns http created" do
      book_params = {
        book: {
          title: "New Book",
          author: "New Author",
          subjects: [ "Science Fiction" ],
          languages: [ "en" ],
          image: "new.jpg"
        }
      }

      post "/api/v1/books", params: book_params
      expect(response).to have_http_status(:created)

      json_response = JSON.parse(response.body)
      expect(json_response["title"]).to eq("New Book")
      expect(json_response["author"]).to eq("New Author")
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
      expect(json_response["title"]).to eq("Test Book")
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
      get "/api/v1/books/search", params: { q: "Test" }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to be_an(Array)
      expect(json_response.first["title"]).to eq("Test Book")
    end

    it "returns bad request for missing query parameter" do
      get "/api/v1/books/search"
      expect(response).to have_http_status(:bad_request)
    end

    it "returns empty array for no matches" do
      get "/api/v1/books/search", params: { q: "Nonexistent" }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to eq([])
    end
  end
end
