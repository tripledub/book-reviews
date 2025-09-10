require 'rails_helper'

RSpec.describe BookService, 'caching' do
  let!(:book1) { Book.create!(title: Faker::Book.title, author: Faker::Book.author, subjects: [ Faker::Book.genre ], languages: [ 'en' ], image: Faker::Internet.url) }
  let!(:book2) { Book.create!(title: Faker::Book.title, author: Faker::Book.author, subjects: [ Faker::Book.genre ], languages: [ 'en' ], image: Faker::Internet.url) }
  let!(:review) { Review.create!(book: book1, title: 'Great book', description: 'Amazing read', score: 5) }

  before do
    # Clear cache before each test
    CacheService.clear
  end

  describe '.cached_paginated_books' do
    it 'caches paginated books data' do
      # First call should cache the data
      result1 = BookService.cached_paginated_books(page: 1, limit: 1)
      expect(result1).to be_an(Array)
      expect(result1.length).to eq(1)

      # Second call should return cached data
      result2 = BookService.cached_paginated_books(page: 1, limit: 1)
      expect(result2).to eq(result1)
    end

    it 'uses correct cache key' do
      expect(CacheKeys).to receive(:books).with(page: 1, limit: 20).and_return('test_key')
      expect(CacheService).to receive(:fetch).with('test_key', expires_in: 1.hour)

      BookService.cached_paginated_books(page: 1, limit: 20)
    end
  end

  describe '.cached_find_book' do
    it 'caches book data' do
      # First call should cache the data
      result1 = BookService.cached_find_book(book1.id)
      expect(result1).to be_a(Hash)
      expect(result1['id']).to eq(book1.id)

      # Second call should return cached data
      result2 = BookService.cached_find_book(book1.id)
      expect(result2).to eq(result1)
    end

    it 'uses correct cache key' do
      expect(CacheKeys).to receive(:book).with(book1.id).and_return('test_key')
      expect(CacheService).to receive(:fetch).with('test_key', expires_in: 2.hours)

      BookService.cached_find_book(book1.id)
    end

    it 'raises error for non-existent book' do
      expect { BookService.cached_find_book(999999) }.to raise_error(ActiveRecord::RecordNotFound)
    end
  end

  describe '.cached_search_books' do
    it 'caches search results' do
      query = book1.title.split.first

      # First call should cache the data
      result1 = BookService.cached_search_books(query)
      expect(result1).to be_an(Array)

      # Second call should return cached data
      result2 = BookService.cached_search_books(query)
      expect(result2).to eq(result1)
    end

    it 'uses correct cache key' do
      query = 'test query'
      expect(CacheKeys).to receive(:search_books).with(query).and_return('test_key')
      expect(CacheService).to receive(:fetch).with('test_key', expires_in: 30.minutes)

      BookService.cached_search_books(query)
    end

    it 'raises error for blank query' do
      expect { BookService.cached_search_books('') }.to raise_error(ArgumentError, 'Search query is required')
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
      expect(CacheKeys).to receive(:highly_rated_books).with(limit: 10).and_return('test_key')
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
      expect(CacheKeys).to receive(:recent_books).with(limit: 10).and_return('test_key')
      expect(CacheService).to receive(:fetch).with('test_key', expires_in: 30.minutes)

      BookService.cached_recent_books(limit: 10)
    end
  end

  describe 'cache invalidation methods' do
    before do
      # Set up some cached data
      BookService.cached_find_book(book1.id)
      BookService.cached_paginated_books(page: 1, limit: 20)
      BookService.cached_search_books('test')
    end

    describe '.invalidate_book_cache' do
      it 'clears cache for specific book' do
        expect(CacheKeys).to receive(:clear_book_cache).with(book1.id)
        BookService.invalidate_book_cache(book1.id)
      end
    end

    describe '.invalidate_all_books_cache' do
      it 'clears all books cache' do
        expect(CacheKeys).to receive(:clear_books_cache)
        BookService.invalidate_all_books_cache
      end
    end

    describe '.invalidate_search_cache' do
      it 'clears search cache' do
        expect(CacheKeys).to receive(:clear_search_cache)
        BookService.invalidate_search_cache
      end
    end

    describe '.invalidate_stats_cache' do
      it 'clears stats cache' do
        expect(CacheKeys).to receive(:clear_stats_cache)
        BookService.invalidate_stats_cache
      end
    end

    describe '.invalidate_highly_rated_cache' do
      it 'clears highly rated cache' do
        expect(CacheKeys).to receive(:clear_highly_rated_cache)
        BookService.invalidate_highly_rated_cache
      end
    end

    describe '.invalidate_recent_cache' do
      it 'clears recent cache' do
        expect(CacheKeys).to receive(:clear_recent_cache)
        BookService.invalidate_recent_cache
      end
    end

    describe '.invalidate_all_cache' do
      it 'clears all cache' do
        expect(CacheKeys).to receive(:clear_all_cache)
        BookService.invalidate_all_cache
      end
    end
  end
end
