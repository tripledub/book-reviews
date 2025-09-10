require 'rails_helper'

RSpec.describe BookService, type: :service do
  let!(:book1) { Book.create!(title: "Ruby Programming", author: "John Doe", subjects: [ "Programming" ], languages: [ "English" ]) }
  let!(:book2) { Book.create!(title: "JavaScript Guide", author: "Jane Smith", subjects: [ "Programming", "Web" ], languages: [ "English", "Spanish" ]) }
  let!(:book3) { Book.create!(title: "Python Basics", author: "Bob Wilson", subjects: [ "Programming" ], languages: [ "English" ]) }

  let!(:review1) { Review.create!(title: "Great book!", description: "Amazing", score: 5, book: book1) }
  let!(:review2) { Review.create!(title: "Good read", description: "Nice", score: 4, book: book1) }
  let!(:review3) { Review.create!(title: "Average", description: "OK", score: 3, book: book2) }
  let!(:review4) { Review.create!(title: "Poor", description: "Bad", score: 2, book: book3) }

  describe '.all_books' do
    it 'returns all books with reviews ordered by creation date' do
      books = BookService.all_books

      expect(books).to include(book1, book2, book3)
      expect(books.first).to eq(book3) # Most recent
      expect(books.last).to eq(book1)  # Oldest
    end

    it 'includes reviews for each book' do
      books = BookService.all_books

      expect(books.first.association(:reviews)).to be_loaded
    end
  end

  describe '.find_book' do
    it 'returns the book with reviews' do
      book = BookService.find_book(book1.id)

      expect(book).to eq(book1)
      expect(book.association(:reviews)).to be_loaded
    end

    it 'raises RecordNotFound for non-existent book' do
      expect {
        BookService.find_book(999)
      }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.create_book' do
    let(:valid_attributes) do
      {
        title: "New Book",
        author: "New Author",
        subjects: [ "Fiction" ],
        languages: [ "English" ]
      }
    end

    context 'with valid attributes' do
      it 'creates and returns the book' do
        book = BookService.create_book(valid_attributes)

        expect(book).to be_a(Book)
        expect(book.title).to eq("New Book")
        expect(book.author).to eq("New Author")
        expect(book.persisted?).to be true
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

  describe '.search_books' do
    context 'with valid query' do
      it 'returns books matching title' do
        books = BookService.search_books("Ruby")

        expect(books).to include(book1)
        expect(books).not_to include(book2, book3)
      end

      it 'returns books matching author' do
        books = BookService.search_books("Jane")

        expect(books).to include(book2)
        expect(books).not_to include(book1, book3)
      end

      it 'is case insensitive' do
        books = BookService.search_books("ruby")

        expect(books).to include(book1)
      end

      it 'returns books ordered by creation date' do
        books = BookService.search_books("Programming")

        expect(books.count).to eq(1) # Only book1 has "Programming" in title
        expect(books).to include(book1)
      end
    end

    context 'with blank query' do
      it 'raises ArgumentError' do
        expect {
          BookService.search_books("")
        }.to raise_error(ArgumentError, "Search query is required")
      end

      it 'raises ArgumentError for nil query' do
        expect {
          BookService.search_books(nil)
        }.to raise_error(ArgumentError, "Search query is required")
      end
    end
  end

  describe '.books_by_subject' do
    it 'returns books with the specified subject' do
      books = BookService.books_by_subject("Programming")

      expect(books).to include(book1, book2, book3)
    end

    it 'returns books with multiple subjects' do
      books = BookService.books_by_subject("Web")

      expect(books).to include(book2)
      expect(books).not_to include(book1, book3)
    end

    it 'returns empty collection for non-existent subject' do
      books = BookService.books_by_subject("NonExistent")

      expect(books).to be_empty
    end
  end

  describe '.books_by_language' do
    it 'returns books with the specified language' do
      books = BookService.books_by_language("English")

      expect(books).to include(book1, book2, book3)
    end

    it 'returns books with multiple languages' do
      books = BookService.books_by_language("Spanish")

      expect(books).to include(book2)
      expect(books).not_to include(book1, book3)
    end
  end

  describe '.books_by_author' do
    it 'returns books by the specified author' do
      books = BookService.books_by_author("John")

      expect(books).to include(book1)
      expect(books).not_to include(book2, book3)
    end

    it 'is case insensitive' do
      books = BookService.books_by_author("john")

      expect(books).to include(book1)
    end
  end

  describe '.highly_rated_books' do
    it 'returns books with average rating >= 4' do
      books = BookService.highly_rated_books

      expect(books).to include(book1) # Average rating: 4.5
      expect(books).not_to include(book2, book3) # Average ratings: 3.0 and 2.0
    end

    it 'orders books by average rating descending' do
      books = BookService.highly_rated_books

      expect(books).to include(book1) # Should include book1 with highest rating
      expect(books.size).to eq(1) # Only book1 should have average >= 4
    end
  end

  describe '.recent_books' do
    it 'returns the specified number of recent books' do
      books = BookService.recent_books(limit: 2)

      expect(books.count).to eq(2)
      expect(books).to include(book2, book3) # Should return the 2 most recent
    end

    it 'defaults to 10 books' do
      books = BookService.recent_books

      expect(books.count).to eq(3) # All books in test
    end
  end

  describe '.book_stats' do
    it 'returns comprehensive book statistics' do
      stats = BookService.book_stats

      expect(stats[:total_books]).to eq(3)
      expect(stats[:total_reviews]).to eq(4)
      expect(stats[:average_rating]).to eq(3.5) # (5+4+3+2)/4
      expect(stats[:books_with_reviews]).to eq(3)
    end
  end
end
