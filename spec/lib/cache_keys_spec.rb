require 'rails_helper'

RSpec.describe CacheKeys do
  describe 'CacheKeys::Book' do
    describe '.paginated' do
      it 'generates correct cache key for books list' do
        key = CacheKeys::Book.paginated(page: 1, limit: 20)
        expect(key).to eq('book_review:book:paginated:page=1:limit=20:origin=api')
      end

      it 'generates correct cache key with different parameters' do
        key = CacheKeys::Book.paginated(page: 2, limit: 10)
        expect(key).to eq('book_review:book:paginated:page=2:limit=10:origin=api')
      end
    end

    describe '.find' do
      it 'generates correct cache key for specific book' do
        key = CacheKeys::Book.find(123)
        expect(key).to eq('book_review:book:find:id=123:origin=api')
      end
    end

    describe '.search' do
      it 'generates correct cache key for search query' do
        key = CacheKeys::Book.search('ruby programming')
        expect(key).to match(/^book_review:book:search:query=[a-f0-9]{32}:page=1:limit=20:origin=api$/)
      end

      it 'generates consistent keys for same query' do
        key1 = CacheKeys::Book.search('ruby programming')
        key2 = CacheKeys::Book.search('ruby programming')
        expect(key1).to eq(key2)
      end

      it 'generates different keys for different queries' do
        key1 = CacheKeys::Book.search('ruby programming')
        key2 = CacheKeys::Book.search('python programming')
        expect(key1).not_to eq(key2)
      end

      it 'handles case insensitive queries consistently' do
        key1 = CacheKeys::Book.search('Ruby Programming')
        key2 = CacheKeys::Book.search('ruby programming')
        expect(key1).to eq(key2)
      end
    end

    describe '.highly_rated' do
      it 'generates correct cache key for highly rated books' do
        key = CacheKeys::Book.highly_rated(limit: 10)
        expect(key).to eq('book_review:book:highly_rated:limit=10:origin=api')
      end
    end

    describe '.recent' do
      it 'generates correct cache key for recent books' do
        key = CacheKeys::Book.recent(limit: 5)
        expect(key).to eq('book_review:book:recent:limit=5:origin=api')
      end
    end
  end

  describe 'CacheKeys::Review' do
    describe '.find' do
      it 'generates correct cache key for specific review' do
        key = CacheKeys::Review.find(123)
        expect(key).to eq('book_review:review:find:id=123:origin=api')
      end
    end

    describe '.paginated' do
      it 'generates correct cache key for reviews list' do
        key = CacheKeys::Review.paginated(page: 1, limit: 20)
        expect(key).to eq('book_review:review:paginated:page=1:limit=20:origin=api')
      end
    end

    describe '.search' do
      it 'generates correct cache key for review search query' do
        key = CacheKeys::Review.search('amazing book')
        expect(key).to match(/^book_review:review:search:query=[a-f0-9]{32}:page=1:limit=20:origin=api$/)
      end
    end
  end
end
