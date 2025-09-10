require 'rails_helper'

RSpec.describe "Books API Pagination", type: :request do
  # Create test data
  let!(:books) do
    25.times.map do |i|
      Book.create!(
        title: "Book #{i + 1}",
        author: "Author #{i + 1}",
        subjects: [ "Fiction" ],
        languages: [ "en" ],
        image: "https://example.com/book#{i + 1}.jpg"
      )
    end
  end

  describe "GET /api/v1/books" do
    context "without pagination parameters (uses defaults)" do
      it "returns paginated books with default pagination metadata" do
        get "/api/v1/books"

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        # Now returns pagination metadata with default settings
        expect(json_response["pagy"]).to be_present
        expect(json_response["pagy"]["count"]).to eq(25)
        expect(json_response["pagy"]["page"]).to eq(1)
        expect(json_response["pagy"]["limit"]).to eq(20) # Default from Pagy config
        expect(json_response["books"]).to be_an(Array)
        expect(json_response["books"].length).to eq(20) # First 20 books
        expect(json_response["books"].first["title"]).to eq("Book 25") # Most recent first
      end
    end

    context "with pagination (now implemented)" do
      it "returns paginated books with pagination metadata" do
        get "/api/v1/books", params: { page: 1, items: 10 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        # Verify pagination metadata structure
        expect(json_response["pagy"]).to be_present
        expect(json_response["pagy"]["count"]).to eq(25)
        expect(json_response["pagy"]["page"]).to eq(1)
        expect(json_response["pagy"]["pages"]).to eq(2) # 25 books ÷ 20 items = 2 pages
        expect(json_response["pagy"]["limit"]).to eq(20) # Default from Pagy config
        expect(json_response["pagy"]["from"]).to eq(1)
        expect(json_response["pagy"]["to"]).to eq(20)
        expect(json_response["pagy"]["prev"]).to be_nil
        expect(json_response["pagy"]["next"]).to eq(2)

        # Verify books array
        expect(json_response["books"]).to be_an(Array)
        expect(json_response["books"].length).to eq(20) # First 20 books
        expect(json_response["books"].first["title"]).to eq("Book 25") # Most recent first
      end

      it "returns second page with correct pagination metadata" do
        get "/api/v1/books", params: { page: 2 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        expect(json_response["pagy"]["page"]).to eq(2)
        expect(json_response["pagy"]["from"]).to eq(21)
        expect(json_response["pagy"]["to"]).to eq(25)
        expect(json_response["pagy"]["prev"]).to eq(1)
        expect(json_response["pagy"]["next"]).to be_nil

        expect(json_response["books"].length).to eq(5) # Only 5 books on last page
        expect(json_response["books"].first["title"]).to eq("Book 5") # Last page, most recent
      end

      it "handles page overflow gracefully" do
        get "/api/v1/books", params: { page: 10 }

        expect(response).to have_http_status(:ok)
        json_response = JSON.parse(response.body)

        # Pagy should return the last page when page number exceeds available pages
        expect(json_response["pagy"]["page"]).to eq(2) # Last available page
        expect(json_response["books"]).to be_an(Array)
        expect(json_response["books"].length).to eq(5) # Only 5 books on last page
      end
    end
  end
end
