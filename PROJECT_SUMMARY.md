# Book Review Application - Project Summary

## 🎯 Project Overview

A full-stack book review application built with **Rails 8.0.2** (API backend) and **React TypeScript** (SPA frontend). The application demonstrates modern Rails architecture patterns including service objects, controller concerns, and exception-driven design for clean, maintainable code.

## 🏗️ Architecture

### Backend (Rails API)
- **Framework**: Rails 8.0.2 with API-only mode
- **Database**: PostgreSQL with native array support and performance indexes
- **Testing**: RSpec with 100% test coverage
- **API Design**: RESTful API with versioning (`api/v1`)
- **Architecture**: Service objects + Controller concerns + Exception-driven design

### Frontend (React TypeScript)
- **Framework**: React 18 with TypeScript
- **Routing**: React Router DOM for client-side navigation
- **Styling**: Tailwind CSS for modern, responsive design
- **Build Tool**: esbuild for fast JavaScript bundling
- **Type Safety**: Full TypeScript implementation with strict mode

## 🏛️ Service Layer Architecture

### BookService
Centralized data access and business logic for books:
```ruby
class BookService
  class << self
    def all_books
      Book.includes(:reviews).order(created_at: :desc)
    end

    def find_book(id)
      Book.includes(:reviews).find(id)
    end

    def create_book(attributes)
      book = Book.new(attributes)
      book.save! # Raises ActiveRecord::RecordInvalid on failure
      book.reload
    end

    def search_books(query)
      raise ArgumentError, "Search query is required" if query.blank?
      Book.includes(:reviews)
          .where("title ILIKE ? OR author ILIKE ?", "%#{query}%", "%#{query}%")
          .order(created_at: :desc)
    end

    def books_by_subject(subject)
      Book.includes(:reviews).where("subjects @> ARRAY[?]", subject)
    end

    def books_by_language(language)
      Book.includes(:reviews).where("languages @> ARRAY[?]", language)
    end

    def highly_rated_books(min_score = 4.0)
      Book.joins(:reviews)
          .group("books.id")
          .having("AVG(reviews.score) >= ?", min_score)
          .order("AVG(reviews.score) DESC")
    end

    def recent_books(limit = 10)
      Book.includes(:reviews).order(created_at: :desc).limit(limit)
    end

    def average_rating_for_book(book_id)
      Review.where(book_id: book_id).average(:score)
    end
  end
end
```

### ReviewService
Centralized data access and business logic for reviews:
```ruby
class ReviewService
  class << self
    def all_reviews
      Review.includes(:book).order(created_at: :desc)
    end

    def find_review(id)
      Review.includes(:book).find(id)
    end

    def create_review(attributes)
      review = Review.new(attributes)
      review.save! # Raises ActiveRecord::RecordInvalid on failure
      review.reload
    end

    def reviews_for_book(book_id)
      Review.includes(:book).where(book_id: book_id).order(created_at: :desc)
    end

    def search_reviews(query)
      raise ArgumentError, "Search query is required" if query.blank?
      Review.includes(:book)
            .where("title ILIKE ? OR description ILIKE ?", "%#{query}%", "%#{query}%")
            .order(created_at: :desc)
    end

    def reviews_by_score(score)
      Review.includes(:book).where(score: score).order(created_at: :desc)
    end

    def recent_reviews(limit = 10)
      Review.includes(:book).order(created_at: :desc).limit(limit)
    end

    def paginated_reviews(page = 1, per_page = 10)
      offset = (page - 1) * per_page
      Review.includes(:book).order(created_at: :desc).limit(per_page).offset(offset)
    end
  end
end
```

## 🎛️ Controller Concerns

### Response Concern
Consistent JSON response handling:
```ruby
module Response
  def json_response(object, status = :ok)
    render json: object, status: status
  end
end
```

### ExceptionHandler Concern
Centralized error handling for all controllers:
```ruby
module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from ActiveRecord::RecordNotFound do |e|
      json_response({ message: e.message }, :not_found)
    end

    rescue_from ActiveRecord::RecordInvalid do |e|
      json_response({ errors: e.record.errors.full_messages }, :unprocessable_content)
    end

    rescue_from ActionController::ParameterMissing do |e|
      json_response({ error: "Required parameters are missing: #{e.param}" }, :bad_request)
    end

    rescue_from ArgumentError do |e|
      json_response({ error: e.message }, :bad_request)
    end
  end
end
```

## 🎯 Controller Architecture

### BooksController with decent_exposure
```ruby
module Api
  module V1
    class BooksController < ApplicationController
      include Response
      include ExceptionHandler

      expose :books, -> { BookService.all_books }
      expose :book, -> { BookService.find_book(params[:id]) }

      def index
        json_response(books.as_json(include: :reviews))
      end

      def create
        save_book
      end

      def show
        json_response(book.as_json(include: :reviews))
      end

      def search
        books = BookService.search_books(params[:q])
        json_response(books.as_json(include: :reviews))
      end

      private

      def save_book
        book = BookService.create_book(book_params)
        json_response(book.as_json(include: :reviews), :created)
      end

      def book_params
        params.require(:book).permit(:title, :author, :image, subjects: [], languages: [])
      end
    end
  end
end
```

### ReviewsController with exception-driven design
```ruby
module Api
  module V1
    class ReviewsController < ApplicationController
      include Response
      include ExceptionHandler

      def create
        save_review
      end

      private

      def save_review
        review = ReviewService.create_review(review_params)
        json_response(review.as_json(include: :book), :created)
      end

      def review_params
        params.require(:review).permit(:title, :description, :score, :book_id)
      end
    end
  end
end
```

## 📊 Data Models

### Book Model
```ruby
class Book < ApplicationRecord
  has_many :reviews, dependent: :destroy
  
  validates :title, presence: true
  validates :author, presence: true
end
```

**Fields:**
- `title` (string) - Book title
- `author` (string) - Book author
- `subjects` (text[]) - Array of subjects/topics
- `languages` (text[]) - Array of available languages
- `image` (string) - Book cover image URL

### Review Model
```ruby
class Review < ApplicationRecord
  belongs_to :book
  
  validates :title, presence: true
  validates :description, presence: true
  validates :score, presence: true, inclusion: { in: 1..5 }
end
```

**Fields:**
- `title` (string) - Review title
- `description` (text) - Review content
- `score` (integer) - Rating (1-5 stars)
- `book_id` (integer) - Foreign key to book

## 🚀 API Endpoints

### Books API (`/api/v1/books`)
- `GET /api/v1/books` - List all books with reviews
- `GET /api/v1/books/:id` - Get specific book with reviews
- `POST /api/v1/books` - Create new book
- `GET /api/v1/books/search?q=query` - Search books by title/author

### Reviews API (`/api/v1/reviews`)
- `POST /api/v1/reviews` - Create new review

**Example Response:**
```json
{
  "id": 1,
  "title": "Great Classic",
  "author": "Jane Austen",
  "subjects": ["Fiction", "Romance"],
  "languages": ["en"],
  "image": "https://example.com/cover.jpg",
  "reviews": [
    {
      "id": 1,
      "title": "Excellent read",
      "description": "A wonderful classic...",
      "score": 5
    }
  ]
}
```

## 🎨 Frontend Components

### App.tsx
- Main application component with navigation
- React Router setup for client-side routing
- Responsive navigation bar

### Books.tsx
- Grid layout displaying all books
- Search functionality with real-time filtering
- Book cards with cover images, titles, authors, and review counts
- Average rating display with star icons

### BookDetail.tsx
- Detailed book view with full information
- Review submission form with CSRF protection
- Review list with star ratings
- Responsive layout with image and details side-by-side

### TypeScript Interfaces
```typescript
interface Book {
  id: number
  title: string
  author: string
  subjects: string[]
  languages: string[]
  image: string
  reviews: Review[]
}

interface Review {
  id: number
  title: string
  description: string
  score: number
  book_id: number
}
```

## 🧪 Testing Strategy

### Backend Testing (RSpec) - 100% Coverage
- **Service Specs**: Comprehensive testing of all service methods (53 examples)
- **Request Specs**: API endpoint testing with JSON expectations
- **Model Specs**: Validation and association testing
- **Exception Testing**: Testing error handling and edge cases

**Service Object Testing Example:**
```ruby
RSpec.describe BookService do
  describe '.create_book' do
    context 'with valid attributes' do
      let(:valid_attributes) { { title: "Test Book", author: "Test Author" } }
      
      it 'creates and returns a book' do
        book = BookService.create_book(valid_attributes)
        expect(book).to be_a(Book)
        expect(book.title).to eq("Test Book")
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { { title: "", author: "" } }
      
      it 'raises RecordInvalid exception' do
        expect {
          BookService.create_book(invalid_attributes)
        }.to raise_error(ActiveRecord::RecordInvalid)
      end
    end
  end
end
```

**Request Spec Testing Example:**
```ruby
RSpec.describe "Api::V1::Books", type: :request do
  describe "GET /api/v1/books" do
    it "returns all books with reviews" do
      get "/api/v1/books"
      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to be_an(Array)
    end
  end
end
```

### Frontend Testing
- TypeScript provides compile-time type checking
- Component testing ready for Jest/React Testing Library

## 🔧 Development Workflow

### Pre-commit Hooks
- **Husky**: Git hooks management
- **lint-staged**: Run linters only on changed files
- **RuboCop**: Ruby code linting and formatting
- **RSpec**: Fast test execution on commit

### CI/CD Pipeline (GitHub Actions)
```yaml
jobs:
  test:
    - PostgreSQL service setup
    - Ruby/Node.js environment
    - Database setup and RSpec execution
  
  scan_ruby:
    - Brakeman security scanning
  
  lint:
    - RuboCop code style checking
```

## 🛠️ Key Technical Decisions

### Database Design & Performance
- **PostgreSQL Arrays**: Native `text[]` for subjects and languages
- **Performance Indexes**: Strategic indexing for search and filtering
  - B-tree indexes on `title`, `author`, `score`, `created_at`
  - GIN indexes on array columns (`subjects`, `languages`)
  - Composite indexes for complex queries
- **No Serialization**: Direct array storage for better performance
- **Foreign Keys**: Proper referential integrity

### API Design
- **Versioning**: `api/v1` namespace for future compatibility
- **JSON Responses**: Consistent API response format
- **Error Handling**: Centralized exception handling with proper HTTP status codes
- **CSRF Protection**: Rails CSRF tokens for POST requests

### Frontend Architecture
- **TypeScript**: Strict type checking for better developer experience
- **Modern React**: Functional components with hooks
- **Responsive Design**: Mobile-first approach with Tailwind CSS
- **Client-side Routing**: SPA navigation without page reloads

### Service Layer Benefits
- **Separation of Concerns**: Business logic separated from controllers
- **Testability**: Easy to unit test business logic
- **Reusability**: Service methods can be used across controllers
- **Maintainability**: Centralized data access patterns
- **Exception-Driven**: Clean error handling with automatic HTTP responses

## 📦 Dependencies

### Backend (Gemfile)
```ruby
gem 'rails', '~> 8.0.2'
gem 'pg'                    # PostgreSQL adapter
gem 'rspec-rails'           # Testing framework
gem 'jsbundling-rails'      # JavaScript bundling
gem 'importmap-rails'       # Import maps for JS
gem 'decent_exposure'       # Declarative controller data access
gem 'rails-controller-testing' # Controller testing support
```

### Frontend (package.json)
```json
{
  "dependencies": {
    "react": "^18.0.0",
    "react-dom": "^18.0.0",
    "react-router-dom": "^6.0.0"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "@types/react": "^18.0.0",
    "esbuild": "^0.19.0",
    "husky": "^9.0.11",
    "lint-staged": "^15.2.2"
  }
}
```

## 🚀 Getting Started

### Prerequisites
- Ruby 3.2+
- Node.js 18+
- PostgreSQL 15+

### Setup
```bash
# Clone and setup
git clone <repository>
cd book-review

# Backend setup
bundle install
rails db:create db:migrate db:seed

# Frontend setup
npm install
npm run build

# Start development server
rails server
```

### Development Commands
```bash
npm run build          # Build TypeScript to JavaScript
npm run type-check     # Run TypeScript type checking
bundle exec rspec      # Run backend tests (100% coverage)
bundle exec rubocop    # Run Ruby linting
```

## 📊 Data Source

The application uses the **Gutendex API** (https://gutendex.com/books/) to seed initial book data, providing:
- Classic literature from Project Gutenberg
- Rich metadata including subjects and languages
- High-quality book cover images

## 🎯 Learning Outcomes

This project demonstrates:

1. **Modern Rails Architecture**: Service objects + Controller concerns + Exception-driven design
2. **Full-Stack Development**: Rails API + React frontend
3. **TypeScript Integration**: Modern type-safe JavaScript development
4. **API Design**: RESTful API with proper versioning and error handling
5. **Database Design**: PostgreSQL arrays, performance indexing, and proper relationships
6. **Testing Strategy**: Comprehensive backend testing with 100% RSpec coverage
7. **CI/CD**: Automated testing and linting with GitHub Actions
8. **Development Workflow**: Pre-commit hooks and code quality tools
9. **Modern Frontend**: React hooks, TypeScript, and responsive design
10. **Clean Code**: Separation of concerns, DRY principles, and maintainable architecture

## 🔮 Future Enhancements

- User authentication and authorization
- Review editing and deletion
- Book recommendations
- Advanced search and filtering
- Image upload for book covers
- Social features (likes, comments)
- Mobile app development
- Performance optimisation and caching
- API rate limiting and throttling
- Background job processing for heavy operations

---

*This project serves as a comprehensive example of modern full-stack web development practices, combining the robustness of Rails with the flexibility of React and TypeScript, while demonstrating advanced architectural patterns for maintainable, testable, and scalable applications.*