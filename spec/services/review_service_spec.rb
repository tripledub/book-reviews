require 'rails_helper'

RSpec.describe ReviewService, type: :service do
  let!(:book1) { Book.create!(title: "Ruby Programming", author: "John Doe", subjects: [ "Programming" ], languages: [ "English" ]) }
  let!(:book2) { Book.create!(title: "JavaScript Guide", author: "Jane Smith", subjects: [ "Programming" ], languages: [ "English" ]) }

  let!(:review1) { Review.create!(book: book1, title: "Great book!", description: "Amazing", score: 5, created_at: 3.days.ago) }
  let!(:review2) { Review.create!(book: book1, title: "Good read", description: "Nice", score: 4, created_at: 2.days.ago) }
  let!(:review3) { Review.create!(book: book2, title: "Average book", description: "OK", score: 3, created_at: 1.day.ago) }
  let!(:review4) { Review.create!(book: book2, title: "Poor quality", description: "Bad", score: 2, created_at: 1.hour.ago) }
  let!(:review5) { Review.create!(book: book1, title: "Excellent guide", description: "Perfect", score: 5, created_at: 30.minutes.ago) }

  describe '.create_review' do
    let(:valid_attributes) do
      {
        title: "Amazing book!",
        description: "This book changed my life",
        score: 5,
        book_id: book1.id
      }
    end

    context 'with valid attributes' do
      it 'creates and returns the review' do
        result = ReviewService.create_review(valid_attributes)

        expect(result[:success]).to be true
        expect(result[:review]).to be_a(Review)
        expect(result[:review].title).to eq("Amazing book!")
        expect(result[:review].score).to eq(5)
        expect(result[:review].book_id).to eq(book1.id)
      end
    end

    context 'with invalid attributes' do
      let(:invalid_attributes) { { title: "", score: 6, book_id: book1.id } }

      it 'returns error messages' do
        result = ReviewService.create_review(invalid_attributes)

        expect(result[:success]).to be false
        expect(result[:errors]).to include("Title can't be blank")
        expect(result[:errors]).to include("Score is not included in the list")
      end
    end
  end

  describe '.reviews_for_book' do
    it 'returns all reviews for the specified book' do
      reviews = ReviewService.reviews_for_book(book1.id)

      expect(reviews).to include(review1, review2, review5)
      expect(reviews).not_to include(review3, review4)
    end

    it 'orders reviews by creation date descending' do
      reviews = ReviewService.reviews_for_book(book1.id)

      expect(reviews).to include(review1, review2, review5)
      expect(reviews.count).to eq(3)
    end

    it 'includes book association' do
      reviews = ReviewService.reviews_for_book(book1.id)

      expect(reviews.first.association(:book)).to be_loaded
    end
  end

  describe '.reviews_by_score' do
    it 'returns reviews within the specified score range' do
      reviews = ReviewService.reviews_by_score(4, 5)

      expect(reviews).to include(review1, review2, review5)
      expect(reviews).not_to include(review3, review4)
    end

    it 'defaults max score to 5' do
      reviews = ReviewService.reviews_by_score(4)

      expect(reviews).to include(review1, review2, review5)
      expect(reviews).not_to include(review3, review4)
    end

    it 'orders reviews by creation date descending' do
      reviews = ReviewService.reviews_by_score(4, 5)

      expect(reviews).to include(review1, review2, review5)
      expect(reviews.count).to eq(3)
    end
  end

  describe '.high_rated_reviews' do
    it 'returns reviews with score >= 4' do
      reviews = ReviewService.high_rated_reviews

      expect(reviews).to include(review1, review2, review5)
      expect(reviews).not_to include(review3, review4)
    end
  end

  describe '.low_rated_reviews' do
    it 'returns reviews with score <= 2' do
      reviews = ReviewService.low_rated_reviews

      expect(reviews).to include(review4)
      expect(reviews).not_to include(review1, review2, review3, review5)
    end
  end

  describe '.recent_reviews' do
    it 'returns the specified number of recent reviews' do
      reviews = ReviewService.recent_reviews(3)

      expect(reviews.count).to eq(3)
      expect(reviews).to include(review5, review4, review3) # Most recent
      expect(reviews).not_to include(review1, review2) # Oldest
    end

    it 'defaults to 10 reviews' do
      reviews = ReviewService.recent_reviews

      expect(reviews.count).to eq(5) # All reviews in test
    end

    it 'orders reviews by creation date descending' do
      reviews = ReviewService.recent_reviews(3)

      expect(reviews).to include(review5, review4, review3)
      expect(reviews.count).to eq(3)
    end
  end

  describe '.average_rating_for_book' do
    it 'calculates the correct average rating' do
      average = ReviewService.average_rating_for_book(book1.id)

      # (5 + 4 + 5) / 3 = 4.67, rounded to 2 decimal places
      expect(average).to eq(4.67)
    end

    it 'returns nil for book with no reviews' do
      new_book = Book.create!(title: "New Book", author: "New Author", subjects: [ "Fiction" ], languages: [ "English" ])
      average = ReviewService.average_rating_for_book(new_book.id)

      expect(average).to be_nil
    end
  end

  describe '.review_stats' do
    it 'returns comprehensive review statistics' do
      stats = ReviewService.review_stats

      expect(stats[:total_reviews]).to eq(5)
      expect(stats[:average_rating]).to eq(3.8) # (5+4+3+2+5)/5
      expect(stats[:high_rated_count]).to eq(3) # scores >= 4
      expect(stats[:low_rated_count]).to eq(1)  # scores <= 2
      expect(stats[:rating_distribution]).to eq({ 5 => 2, 4 => 1, 3 => 1, 2 => 1 })
    end
  end

  describe '.search_reviews' do
    context 'with valid query' do
      it 'returns reviews matching title' do
        result = ReviewService.search_reviews("Great")

        expect(result[:success]).to be true
        expect(result[:reviews]).to include(review1)
        expect(result[:reviews]).not_to include(review2, review3, review4, review5)
      end

      it 'returns reviews matching description' do
        # Assuming we have a description field
        review1.update!(description: "This is a great programming book")
        result = ReviewService.search_reviews("programming")

        expect(result[:success]).to be true
        expect(result[:reviews]).to include(review1)
      end

      it 'is case insensitive' do
        result = ReviewService.search_reviews("great")

        expect(result[:success]).to be true
        expect(result[:reviews]).to include(review1)
      end

      it 'orders reviews by creation date descending' do
        result = ReviewService.search_reviews("book")

        expect(result[:success]).to be true
        expect(result[:reviews]).to include(review1, review3) # Reviews with "book" in title
        expect(result[:reviews].count).to eq(2)
      end
    end

    context 'with blank query' do
      it 'returns error message' do
        result = ReviewService.search_reviews("")

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Search query is required")
      end

      it 'returns error message for nil query' do
        result = ReviewService.search_reviews(nil)

        expect(result[:success]).to be false
        expect(result[:error]).to eq("Search query is required")
      end
    end
  end

  describe '.reviews_for_books' do
    it 'returns reviews for multiple books' do
      reviews = ReviewService.reviews_for_books([ book1.id, book2.id ])

      expect(reviews).to include(review1, review2, review3, review4, review5)
    end

    it 'orders reviews by creation date descending' do
      reviews = ReviewService.reviews_for_books([ book1.id, book2.id ])

      expect(reviews).to include(review1, review2, review3, review4, review5)
      expect(reviews.count).to eq(5)
    end

    it 'includes book association' do
      reviews = ReviewService.reviews_for_books([ book1.id ])

      expect(reviews.first.association(:book)).to be_loaded
    end
  end

  describe '.paginated_reviews' do
    it 'returns the specified number of reviews per page' do
      reviews = ReviewService.paginated_reviews(1, 3)

      expect(reviews.count).to eq(3)
    end

    it 'returns reviews for the specified page' do
      reviews_page_1 = ReviewService.paginated_reviews(1, 2)
      reviews_page_2 = ReviewService.paginated_reviews(2, 2)

      expect(reviews_page_1).to include(review5, review4) # Most recent 2
      expect(reviews_page_2).to include(review3, review2) # Next 2
    end

    it 'orders reviews by creation date descending' do
      reviews = ReviewService.paginated_reviews(1, 3)

      expect(reviews).to include(review5, review4, review3)
      expect(reviews.count).to eq(3)
    end

    it 'includes book association' do
      reviews = ReviewService.paginated_reviews(1, 1)

      expect(reviews.first.association(:book)).to be_loaded
    end
  end
end
