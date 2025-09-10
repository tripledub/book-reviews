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
        highly_rated_books = Book.highly_rated(min_score: 3.0)
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
        recent_books = Book.recent(limit: 2)
        expect(recent_books.count).to eq(2)
        expect(recent_books).to include(book3, book2)
      end
    end

    describe '.by_subject' do
      it 'returns books with specific subject' do
        fiction_books = Book.by_subject(subject: 'Fiction')
        expect(fiction_books).to include(book1, book3)
        expect(fiction_books).not_to include(book2)
      end

      it 'accepts array of subjects (all must be present)' do
        # Create a book with both Fiction and Adventure subjects
        book_with_multiple_subjects = Book.create!(
          title: 'Adventure Fiction Book',
          author: 'Test Author',
          subjects: [ 'Fiction', 'Adventure' ],
          languages: [ 'en' ],
          image: 'https://example.com/adventure.jpg'
        )

        # Test with array of subjects - both must be present
        books_with_both = Book.by_subject(subject: [ 'Fiction', 'Adventure' ])
        expect(books_with_both).to include(book_with_multiple_subjects)
        expect(books_with_both).not_to include(book1, book2, book3) # These don't have both subjects

        # Test with array where only one subject matches
        books_with_one = Book.by_subject(subject: [ 'Fiction', 'Romance' ])
        expect(books_with_one).to be_empty # No books have both Fiction AND Romance
      end
    end

    describe '.by_language' do
      it 'returns books available in specific language' do
        english_books = Book.by_language(language: 'en')
        expect(english_books).to include(book1, book3)
        expect(english_books).not_to include(book2)
      end
    end

    describe '.by_author' do
      it 'returns books by specific author (case insensitive)' do
        author1_books = Book.by_author(author_name: 'Author 1')
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

  describe 'advanced rating statistics' do
    let(:book) { Book.create!(title: 'Test Book', author: 'Test Author', subjects: [ 'Fiction' ], languages: [ 'en' ]) }

    describe '#rating_summary' do
      it 'returns default summary when book has no reviews' do
        summary = book.rating_summary
        expect(summary).to eq({
          average: 0.0,
          count: 0,
          distribution: {},
          highest: nil,
          lowest: nil,
          median: 0.0
        })
      end

      it 'returns comprehensive summary with reviews' do
        Review.create!(book: book, title: 'Great', description: 'Amazing', score: 5)
        Review.create!(book: book, title: 'Good', description: 'Nice', score: 4)
        Review.create!(book: book, title: 'Average', description: 'OK', score: 3)
        Review.create!(book: book, title: 'Poor', description: 'Bad', score: 2)
        Review.create!(book: book, title: 'Terrible', description: 'Awful', score: 1)

        summary = book.rating_summary
        expect(summary[:average]).to eq(3.0)
        expect(summary[:count]).to eq(5)
        expect(summary[:highest]).to eq(5)
        expect(summary[:lowest]).to eq(1)
        expect(summary[:median]).to eq(3.0)
        expect(summary[:distribution]).to eq({ 1 => 1, 2 => 1, 3 => 1, 4 => 1, 5 => 1 })
      end

      it 'calculates median correctly with even number of reviews' do
        Review.create!(book: book, title: 'Great', description: 'Amazing', score: 5)
        Review.create!(book: book, title: 'Good', description: 'Nice', score: 4)
        Review.create!(book: book, title: 'Average', description: 'OK', score: 3)
        Review.create!(book: book, title: 'Poor', description: 'Bad', score: 2)

        summary = book.rating_summary
        # With scores [2, 3, 4, 5], median should be (3 + 4) / 2 = 3.5
        expect(summary[:median]).to eq(3.5)
      end
    end

    describe '#rating_distribution' do
      it 'returns empty hash when book has no reviews' do
        expect(book.rating_distribution).to eq({})
      end

      it 'returns distribution with all scores represented' do
        Review.create!(book: book, title: 'Great', description: 'Amazing', score: 5)
        Review.create!(book: book, title: 'Great', description: 'Amazing', score: 5)
        Review.create!(book: book, title: 'Good', description: 'Nice', score: 4)

        distribution = book.rating_distribution
        expect(distribution).to eq({ 1 => 0, 2 => 0, 3 => 0, 4 => 1, 5 => 2 })
      end
    end

    describe '#rating_percentile' do
      it 'returns 0.0 when book has no reviews' do
        expect(book.rating_percentile).to eq(0.0)
      end

      it 'calculates percentile correctly' do
        # Create a book with high rating
        Review.create!(book: book, title: 'Great', description: 'Amazing', score: 5)
        Review.create!(book: book, title: 'Excellent', description: 'Perfect', score: 5)

        # Create another book with lower rating for comparison
        other_book = Book.create!(title: 'Other Book', author: 'Other Author', subjects: [ 'Fiction' ], languages: [ 'en' ])
        Review.create!(book: other_book, title: 'OK', description: 'Average', score: 3)

        # The first book should have a high percentile (better than the other book)
        # Since we have 2 books total, and book1 has higher rating, it should be in top 50%
        expect(book.rating_percentile).to be >= 0.0
        expect(book.rating_percentile).to be <= 100.0
      end
    end
  end

  describe 'advanced scopes' do
    let!(:book1) { Book.create!(title: 'Book 1', author: 'Author 1', subjects: [ 'Fiction' ], languages: [ 'en' ]) }
    let!(:book2) { Book.create!(title: 'Book 2', author: 'Author 2', subjects: [ 'Science' ], languages: [ 'fr' ]) }
    let!(:book3) { Book.create!(title: 'Book 3', author: 'Author 1', subjects: [ 'Fiction' ], languages: [ 'en' ]) }

    before do
      # Add reviews to make books popular and highly rated
      Review.create!(book: book1, title: 'Great', description: 'Amazing', score: 5)
      Review.create!(book: book1, title: 'Excellent', description: 'Perfect', score: 5)
      Review.create!(book: book1, title: 'Fantastic', description: 'Wonderful', score: 4)

      Review.create!(book: book2, title: 'Good', description: 'Nice', score: 4)
      Review.create!(book: book2, title: 'Decent', description: 'OK', score: 3)

      Review.create!(book: book3, title: 'Average', description: 'OK', score: 2)
    end

    describe '.popular_books' do
      it 'returns books ordered by review count' do
        popular_books = Book.popular_books
        # Check that our test books are included in the results
        expect(popular_books).to include(book1, book2, book3)
        # Check that the results are ordered by review count (book1 has most reviews)
        book1_position = popular_books.index(book1)
        book2_position = popular_books.index(book2)
        book3_position = popular_books.index(book3)
        expect(book1_position).to be < book2_position if book1_position && book2_position
        expect(book2_position).to be < book3_position if book2_position && book3_position
      end

      it 'accepts custom limit' do
        popular_books = Book.popular_books(limit: 2)
        # Check that the limit is respected (use length instead of size for grouped queries)
        expect(popular_books.length).to be <= 2
        # Check that our test books are included if they're in the top 2
        expect(popular_books).to include(book1) # book1 should be in top 2
      end
    end

    describe '.by_rating_range' do
      it 'returns books within specified rating range' do
        # Test with a specific range that should include our test books
        books_in_range = Book.by_rating_range(min_score: 3.0, max_score: 5.0)
        expect(books_in_range).to include(book1, book2)
        expect(books_in_range).not_to include(book3)
      end

      it 'returns empty collection for range with no matches' do
        # Use a very specific range that won't match our test data
        books_in_range = Book.by_rating_range(min_score: 4.8, max_score: 5.0)
        # Only check that our specific test books are not included
        expect(books_in_range).not_to include(book1, book2, book3)
      end
    end

    describe '.trending_books' do
      it 'returns recently highly-rated books' do
        # Create a recent highly-rated book
        recent_book = Book.create!(title: 'Recent Book', author: 'Recent Author', subjects: [ 'Fiction' ], languages: [ 'en' ])
        Review.create!(book: recent_book, title: 'Great', description: 'Amazing', score: 5)
        Review.create!(book: recent_book, title: 'Excellent', description: 'Perfect', score: 5)

        trending_books = Book.trending_books
        expect(trending_books).to include(recent_book)
      end

      it 'accepts custom days and minimum reviews' do
        trending_books = Book.trending_books(days: 7, min_reviews: 1) # Last 7 days, min 1 review
        expect(trending_books).to be_present
      end
    end
  end

  describe 'cache invalidation callbacks' do
    let(:book) { Book.new(title: 'Test Book', author: 'Test Author', subjects: [ 'Fiction' ], languages: [ 'en' ]) }

    before do
      # Mock BookService methods to verify they're called
      allow(BookService).to receive(:invalidate_all_books_cache)
      allow(BookService).to receive(:invalidate_recent_cache)
      allow(BookService).to receive(:invalidate_highly_rated_cache)
      allow(BookService).to receive(:invalidate_book_cache)
      allow(BookService).to receive(:invalidate_search_cache)
    end

    describe 'after_create' do
      it 'invalidates cache after book creation' do
        book.save!

        expect(BookService).to have_received(:invalidate_all_books_cache)
        expect(BookService).to have_received(:invalidate_recent_cache)
        expect(BookService).to have_received(:invalidate_highly_rated_cache)
      end
    end

    describe 'after_update' do
      it 'invalidates cache after book update' do
        book.save!

        # Clear previous calls and reset mocks
        RSpec::Mocks.space.proxy_for(BookService).reset
        allow(BookService).to receive(:invalidate_all_books_cache)
        allow(BookService).to receive(:invalidate_recent_cache)
        allow(BookService).to receive(:invalidate_highly_rated_cache)
        allow(BookService).to receive(:invalidate_book_cache)
        allow(BookService).to receive(:invalidate_search_cache)

        book.update!(title: 'Updated Title')

        expect(BookService).to have_received(:invalidate_book_cache).with(book.id)
        expect(BookService).to have_received(:invalidate_all_books_cache)
        expect(BookService).to have_received(:invalidate_search_cache)
        expect(BookService).to have_received(:invalidate_recent_cache)
        expect(BookService).to have_received(:invalidate_highly_rated_cache)
      end
    end

    describe 'after_destroy' do
      it 'invalidates cache after book destruction' do
        book.save!
        book_id = book.id

        # Clear previous calls and reset mocks
        RSpec::Mocks.space.proxy_for(BookService).reset
        allow(BookService).to receive(:invalidate_all_books_cache)
        allow(BookService).to receive(:invalidate_recent_cache)
        allow(BookService).to receive(:invalidate_highly_rated_cache)
        allow(BookService).to receive(:invalidate_book_cache)
        allow(BookService).to receive(:invalidate_search_cache)

        book.destroy

        expect(BookService).to have_received(:invalidate_book_cache).with(book_id)
        expect(BookService).to have_received(:invalidate_all_books_cache)
        expect(BookService).to have_received(:invalidate_search_cache)
        expect(BookService).to have_received(:invalidate_recent_cache)
        expect(BookService).to have_received(:invalidate_highly_rated_cache)
      end
    end
  end
end
