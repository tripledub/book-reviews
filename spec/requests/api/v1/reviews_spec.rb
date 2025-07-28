require "rails_helper"

RSpec.describe "Api::V1::Reviews", type: :request do
  let!(:book) { Book.create!(title: "Test Book", author: "Test Author", subjects: ["Fiction"], languages: ["en"], image: "test.jpg") }

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
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Title can't be blank")
      end

      it "returns unprocessable entity for missing description" do
        review_params = {
          review: {
            title: "Great Book",
            score: 4,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Description can't be blank")
      end

      it "returns unprocessable entity for missing score" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Score can't be blank")
      end

      it "returns unprocessable entity for invalid score" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            score: 6,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Score is not included in the list")
      end

      it "returns unprocessable entity for score below 1" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            score: 0,
            book_id: book.id
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_entity)

        json_response = JSON.parse(response.body)
        expect(json_response["errors"]).to include("Score is not included in the list")
      end

      it "returns unprocessable entity for invalid book_id" do
        review_params = {
          review: {
            title: "Great Book",
            description: "Amazing read",
            score: 4,
            book_id: 999999
          }
        }

        post "/api/v1/reviews", params: review_params
        expect(response).to have_http_status(:unprocessable_entity)

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
end
