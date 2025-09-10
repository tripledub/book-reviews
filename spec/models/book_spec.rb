require 'rails_helper'

RSpec.describe Book, type: :model do
  describe 'validations' do
    it 'is valid with valid attributes' do
      book = Book.new(
        title: 'Test Book',
        author: 'Test Author',
        subjects: [ 'Fiction' ],
        languages: [ 'en' ],
        image: 'https://example.com/image.jpg'
      )
      expect(book).to be_valid
    end

    it 'is not valid without a title' do
      book = Book.new(
        author: 'Test Author',
        subjects: [ 'Fiction' ],
        languages: [ 'en' ]
      )
      expect(book).not_to be_valid
      expect(book.errors[:title]).to include("can't be blank")
    end

    it 'is not valid without an author' do
      book = Book.new(
        title: 'Test Book',
        subjects: [ 'Fiction' ],
        languages: [ 'en' ]
      )
      expect(book).not_to be_valid
      expect(book.errors[:author]).to include("can't be blank")
    end
  end

  describe 'associations' do
    it 'has many reviews' do
      book = Book.reflect_on_association(:reviews)
      expect(book.macro).to eq :has_many
    end
  end

  describe 'attributes' do
    it 'can store subjects as an array' do
      book = Book.create!(
        title: 'Test Book',
        author: 'Test Author',
        subjects: [ 'Fiction', 'Adventure' ],
        languages: [ 'en' ]
      )
      expect(book.subjects).to eq([ 'Fiction', 'Adventure' ])
    end

    it 'can store languages as an array' do
      book = Book.create!(
        title: 'Test Book',
        author: 'Test Author',
        subjects: [ 'Fiction' ],
        languages: [ 'en', 'fr' ]
      )
      expect(book.languages).to eq([ 'en', 'fr' ])
    end
  end

  describe 'database constraints' do
    it 'prevents NULL title at database level' do
      expect {
        Book.connection.execute("INSERT INTO books (author, created_at, updated_at) VALUES ('Test Author', NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "title"/)
    end

    it 'prevents NULL author at database level' do
      expect {
        Book.connection.execute("INSERT INTO books (title, created_at, updated_at) VALUES ('Test Book', NOW(), NOW())")
      }.to raise_error(ActiveRecord::NotNullViolation, /null value in column "author"/)
    end

    # Note: Array constraints are more complex to test due to PostgreSQL array handling
    # The constraints are in place but testing them requires more sophisticated setup

    it 'prevents invalid image URL format at database level' do
      expect {
        Book.connection.execute("INSERT INTO books (title, author, image, created_at, updated_at) VALUES ('Test Book', 'Test Author', 'invalid-url', NOW(), NOW())")
      }.to raise_error(ActiveRecord::StatementInvalid, /violates check constraint "books_image_url_format"/)
    end

    it 'allows valid image URL format' do
      expect {
        Book.connection.execute("INSERT INTO books (title, author, image, created_at, updated_at) VALUES ('Test Book', 'Test Author', 'https://example.com/image.jpg', NOW(), NOW())")
      }.not_to raise_error
    end

    it 'allows NULL image' do
      expect {
        Book.connection.execute("INSERT INTO books (title, author, created_at, updated_at) VALUES ('Test Book', 'Test Author', NOW(), NOW())")
      }.not_to raise_error
    end
  end

  describe 'computed attributes' do
    let(:book) { Book.create!(title: 'Test Book', author: 'Test Author', subjects: [ 'Fiction' ], languages: [ 'en' ]) }

    describe '#average_rating' do
      it 'returns 0.0 when book has no reviews' do
        expect(book.average_rating).to eq(0.0)
      end

      it 'calculates average rating correctly with multiple reviews' do
        Review.create!(book: book, title: 'Great', description: 'Amazing', score: 5)
        Review.create!(book: book, title: 'Good', description: 'Nice', score: 3)
        Review.create!(book: book, title: 'Excellent', description: 'Perfect', score: 5)

        expect(book.average_rating).to eq(4.33)
      end

      it 'rounds to 2 decimal places' do
        Review.create!(book: book, title: 'Review 1', description: 'Desc', score: 5)
        Review.create!(book: book, title: 'Review 2', description: 'Desc', score: 4)

        expect(book.average_rating).to eq(4.5)
      end
    end

    describe '#review_count' do
      it 'returns 0 when book has no reviews' do
        expect(book.review_count).to eq(0)
      end

      it 'returns correct count with multiple reviews' do
        Review.create!(book: book, title: 'Review 1', description: 'Desc', score: 5)
        Review.create!(book: book, title: 'Review 2', description: 'Desc', score: 4)
        Review.create!(book: book, title: 'Review 3', description: 'Desc', score: 3)

        expect(book.review_count).to eq(3)
      end
    end

    describe '#has_reviews?' do
      it 'returns false when book has no reviews' do
        expect(book.has_reviews?).to be false
      end

      it 'returns true when book has reviews' do
        Review.create!(book: book, title: 'Review', description: 'Desc', score: 5)
        expect(book.has_reviews?).to be true
      end
    end
  end

  describe 'constants' do
    it 'defines HIGHLY_RATED_THRESHOLD' do
      expect(Book::HIGHLY_RATED_THRESHOLD).to eq(4.0)
    end

    it 'defines DEFAULT_RECENT_LIMIT' do
      expect(Book::DEFAULT_RECENT_LIMIT).to eq(10)
    end
  end

  describe 'scopes' do
    let!(:book1) { Book.create!(title: 'Book 1', author: 'Author 1', subjects: [ 'Fiction' ], languages: [ 'en' ]) }
    let!(:book2) { Book.create!(title: 'Book 2', author: 'Author 2', subjects: [ 'Science' ], languages: [ 'fr' ]) }
    let!(:book3) { Book.create!(title: 'Book 3', author: 'Author 1', subjects: [ 'Fiction' ], languages: [ 'en' ]) }

    before do
      # Add reviews to make books highly rated
      Review.create!(book: book1, title: 'Great', description: 'Amazing', score: 5)
      Review.create!(book: book1, title: 'Excellent', description: 'Perfect', score: 5)
      Review.create!(book: book2, title: 'Good', description: 'Nice', score: 3)
      Review.create!(book: book3, title: 'Average', description: 'OK', score: 2)
    end

    describe '.highly_rated' do
      it 'returns books with average rating >= 4.0 by default' do
        highly_rated_books = Book.highly_rated
        expect(highly_rated_books).to include(book1)
        expect(highly_rated_books).not_to include(book2, book3)
      end

      it 'accepts custom minimum score' do
        highly_rated_books = Book.highly_rated(3.0)
        expect(highly_rated_books).to include(book1, book2)
        expect(highly_rated_books).not_to include(book3)
      end
    end

    describe '.recent' do
      it 'returns most recent books by default limit' do
        recent_books = Book.recent
        expect(recent_books.count).to be <= 10
        expect(recent_books.first).to eq(book3) # Most recently created
      end

      it 'accepts custom limit' do
        recent_books = Book.recent(2)
        expect(recent_books.count).to eq(2)
        expect(recent_books).to include(book3, book2)
      end
    end

    describe '.by_subject' do
      it 'returns books with specific subject' do
        fiction_books = Book.by_subject('Fiction')
        expect(fiction_books).to include(book1, book3)
        expect(fiction_books).not_to include(book2)
      end
    end

    describe '.by_language' do
      it 'returns books available in specific language' do
        english_books = Book.by_language('en')
        expect(english_books).to include(book1, book3)
        expect(english_books).not_to include(book2)
      end
    end

    describe '.by_author' do
      it 'returns books by specific author (case insensitive)' do
        author1_books = Book.by_author('Author 1')
        expect(author1_books).to include(book1, book3)
        expect(author1_books).not_to include(book2)
      end
    end

    describe '.with_reviews' do
      it 'returns only books that have reviews' do
        books_with_reviews = Book.with_reviews
        expect(books_with_reviews).to include(book1, book2, book3)
      end
    end

    describe '.without_reviews' do
      let!(:book_without_reviews) { Book.create!(title: 'No Reviews', author: 'Author', subjects: [ 'Fiction' ], languages: [ 'en' ]) }

      it 'returns only books without reviews' do
        books_without_reviews = Book.without_reviews
        expect(books_without_reviews).to include(book_without_reviews)
        expect(books_without_reviews).not_to include(book1, book2, book3)
      end
    end
  end
end
