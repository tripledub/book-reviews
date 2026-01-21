require 'rails_helper'

RSpec.describe BookService, 'caching' do
  let!(:book1) { Book.create!(title: Faker::Book.title, author: Faker::Book.author, subjects: [ Faker::Book.genre ], languages: [ 'en' ], image: Faker::Internet.url) }
  let!(:book2) { Book.create!(title: Faker::Book.title, author: Faker::Book.author, subjects: [ Faker::Book.genre ], languages: [ 'en' ], image: Faker::Internet.url) }
  let!(:review) { Review.create!(book: book1, title: 'Great book', description: 'Amazing read', score: 5) }

  before do
    # Clear cache before each test
    CacheService.clear
  end

  describe '.all_books' do
    it 'returns books relation for pagination' do
      result = BookService.all_books
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result.to_sql).to include('ORDER BY "books"."created_at" DESC')
    end
  end

  describe '.find_book' do
    it 'caches book data' do
      # First call should cache the data
      result1 = BookService.find_book(book1.id)
      expect(result1).to be_a(Hash)
      expect(result1['id']).to eq(book1.id)

      # Second call should return cached data
      result2 = BookService.find_book(book1.id)
      expect(result2).to eq(result1)
    end

    it 'uses correct cache key' do
      expect(CacheKeys::Book).to receive(:find).with(book1.id).and_return('test_key')
      expect(CacheService).to receive(:fetch).with('test_key', expires_in: 2.hours)

      BookService.find_book(book1.id)
    end

    it 'raises error for non-existent book' do
      expect { BookService.find_book(999999) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.search_books' do
    it 'returns search results relation' do
      query = book1.title.split.first
      result = BookService.search_books(query)
      expect(result).to be_a(ActiveRecord::Relation)
      expect(result.to_sql).to include('ILIKE')
    end

    it 'raises error for blank query' do
      expect { BookService.search_books('') }.to raise_error(ArgumentError, 'Search query is required')
    end
  end

  describe '.cached_highly_rated_books' do
    it 'caches highly rated books data' do
      # First call should cache the data
      result1 = BookService.cached_highly_rated_books(limit: 5)
      expect(result1).to be_an(Array)

      # Second call should return cached data
      result2 = BookService.cached_highly_rated_books(limit: 5)
      expect(result2).to eq(result1)
    end

    it 'uses correct cache key' do
      expect(CacheKeys::Book).to receive(:highly_rated).with(limit: 10).and_return('test_key')
      expect(CacheService).to receive(:fetch).with('test_key', expires_in: 1.hour)

      BookService.cached_highly_rated_books(limit: 10)
    end
  end

  describe '.cached_recent_books' do
    it 'caches recent books data' do
      # First call should cache the data
      result1 = BookService.cached_recent_books(limit: 5)
      expect(result1).to be_an(Array)

      # Second call should return cached data
      result2 = BookService.cached_recent_books(limit: 5)
      expect(result2).to eq(result1)
    end

    it 'uses correct cache key' do
      expect(CacheKeys::Book).to receive(:recent).with(limit: 10).and_return('test_key')
      expect(CacheService).to receive(:fetch).with('test_key', expires_in: 30.minutes)

      BookService.cached_recent_books(limit: 10)
    end
  end

  describe 'cache invalidation methods' do
    before do
      # Set up some cached data
      BookService.find_book(book1.id)
      BookService.all_books
      BookService.search_books('test')
    end

    describe '.invalidate_book_cache' do
      it 'clears cache for specific book' do
        expect(CacheKeys::Book).to receive(:pattern_for_book).with(book1.id).and_return('pattern')
        expect(CacheService).to receive(:keys).with('pattern').and_return([ 'key1', 'key2' ])
        expect(CacheService).to receive(:delete).with([ 'key1', 'key2' ]).and_return(2)
        BookService.invalidate_book_cache(book1.id)
      end
    end

    describe '.invalidate_all_books_cache' do
      it 'clears all books cache' do
        expect(CacheKeys::Book).to receive(:clear_all).and_return(5)
        BookService.invalidate_all_books_cache
      end
    end

    describe '.invalidate_search_cache' do
      it 'clears search cache' do
        expect(CacheKeys::Book).to receive(:clear_search).and_return(3)
        BookService.invalidate_search_cache
      end
    end

    describe '.invalidate_stats_cache' do
      it 'clears stats cache' do
        # This method now returns 0 for backward compatibility
        result = BookService.invalidate_stats_cache
        expect(result).to eq(0)
      end
    end

    describe '.invalidate_highly_rated_cache' do
      it 'clears highly rated cache' do
        expect(CacheService).to receive(:keys).with('book_review:book:highly_rated:*').and_return([ 'key1' ])
        expect(CacheService).to receive(:delete).with([ 'key1' ]).and_return(1)
        BookService.invalidate_highly_rated_cache
      end
    end

    describe '.invalidate_recent_cache' do
      it 'clears recent cache' do
        expect(CacheService).to receive(:keys).with('book_review:book:recent:*').and_return([ 'key1' ])
        expect(CacheService).to receive(:delete).with([ 'key1' ]).and_return(1)
        BookService.invalidate_recent_cache
      end
    end

    describe '.invalidate_all_cache' do
      it 'clears all cache' do
        expect(CacheService).to receive(:keys).with('book_review:*').and_return([ 'key1', 'key2' ])
        expect(CacheService).to receive(:delete).with([ 'key1', 'key2' ]).and_return(2)
        BookService.invalidate_all_cache
      end
    end
  end
end
