require "rails_helper"

RSpec.describe "Api::V1::Reviews", type: :request do
  let!(:book) { Book.create!(title: "Test Book", author: "Test Author", subjects: [ "Fiction" ], languages: [ "en" ], image: "https://example.com/test.jpg") }

  describe "POST /api/v1/reviews" do
    context "with valid parameters" do
      it "creates a new review and returns http created" do
        review_params = {
          review: {
            title: "Amazing Book!",
            description: "This book was absolutely fantastic. Highly recommend!",
            score: 5,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:created)

        json_response = JSON.parse(response.body)
        expect(json_response["title"]).to eq("Amazing Book!")
        expect(json_response["description"]).to eq("This book was absolutely fantastic. Highly recommend!")
        expect(json_response["score"]).to eq(5)
        expect(json_response["book_id"]).to eq(book.id)
        expect(json_response["book"]).to be_present
        expect(json_response["book"]["title"]).to eq("Test Book")
      end
    end

    context "with invalid parameters" do
      it "returns unprocessable entity for missing title" do
        review_params = {
          review: {
            description: "Great book",
            score: 4,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Title can't be blank")
      end

      it "returns unprocessable content for missing description" do
        review_params = {
          review: {
            title: "Great Book",
            score: 4,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Description can't be blank")
      end

      it "returns unprocessable content for missing score" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Score can't be blank")
      end

      it "returns unprocessable content for invalid score" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            score: 6,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Score is not included in the list")
      end

      it "returns unprocessable content for score below 1" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            score: 0,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Score is not included in the list")
      end

      it "returns unprocessable content for invalid book_id" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            score: 4,
            book_id: 999999
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_content)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Book must exist")
      end
    end

    context "with missing review parameters" do
      it "returns bad request when review params are missing" do
        post "/api/v1/reviews", params: {}
        expect(response).to have_http_status(:bad_request)
      end
    end
  end

  describe "GET /api/v1/reviews" do
    let!(:review) { Review.create!(book: book, title: "Great Book", description: "Amazing read", score: 5) }

    it "returns http success and reviews with books" do
      get "/api/v1/reviews"
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("reviews")
      expect(json_response).to have_key("pagy")
      expect(json_response["reviews"]).to be_an(Array)
      expect(json_response["reviews"].first["title"]).to eq(review.title)
      expect(json_response["reviews"].first["book"]).to be_present
    end
  end

  describe "GET /api/v1/reviews/:id" do
    let!(:review) { Review.create!(book: book, title: "Great Book", description: "Amazing read", score: 5) }

    it "returns http success and review with book" do
      get "/api/v1/reviews/#{review.id}"
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["title"]).to eq(review.title)
      expect(json_response["book"]).to be_present
    end

    it "returns not found for invalid id" do
      get "/api/v1/reviews/999999"
      expect(response).to have_http_status(:not_found)
    end
  end

  describe "GET /api/v1/reviews/search" do
    let!(:review) { Review.create!(book: book, title: "Great Book", description: "Amazing read", score: 5) }

    it "returns http success for valid search query" do
      get "/api/v1/reviews/search", params: { q: review.title.split.first }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("reviews")
      expect(json_response).to have_key("pagy")
      expect(json_response["reviews"]).to be_an(Array)
      expect(json_response["reviews"].first["title"]).to eq(review.title)
    end

    it "returns bad request for missing query parameter" do
      get "/api/v1/reviews/search"
      expect(response).to have_http_status(:bad_request)
    end

    it "returns empty array for no matches" do
      get "/api/v1/reviews/search", params: { q: "Nonexistent" }
      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response).to have_key("reviews")
      expect(json_response).to have_key("pagy")
      expect(json_response["reviews"]).to eq([])
    end
  end
end
