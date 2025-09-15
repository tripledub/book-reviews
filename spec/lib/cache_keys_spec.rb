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

    describe '.by_subject' do
      it 'generates correct cache key for books by subject' do
        key = CacheKeys::Book.by_subject('Science Fiction')
        expect(key).to eq('book_review:book:by_subject:subject=Science_Fiction:origin=api')
      end

      it 'sanitizes subject names with special characters' do
        key = CacheKeys::Book.by_subject('Science & Technology!')
        expect(key).to eq('book_review:book:by_subject:subject=Science_Technology:origin=api')
      end
    end

    describe '.by_language' do
      it 'generates correct cache key for books by language' do
        key = CacheKeys::Book.by_language('English')
        expect(key).to eq('book_review:book:by_language:language=English:origin=api')
      end
    end

    describe '.search_pattern' do
      it 'generates correct pattern for search cache keys' do
        pattern = CacheKeys::Book.search_pattern
        expect(pattern).to eq('book_review:book:search:*')
      end
    end

    describe '.clear_search' do
      it 'clears all search cache keys' do
        # Mock CacheService to return some keys
        allow(CacheService).to receive(:keys).with('book_review:book:search:*').and_return([ 'key1', 'key2' ])
        allow(CacheService).to receive(:delete).with([ 'key1', 'key2' ]).and_return(2)

        result = CacheKeys::Book.clear_search
        expect(result).to eq(2)
      end

      it 'returns 0 when no search keys exist' do
        allow(CacheService).to receive(:keys).with('book_review:book:search:*').and_return([])

        result = CacheKeys::Book.clear_search
        expect(result).to eq(0)
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

    describe '.by_book' do
      it 'generates correct cache key for reviews by book' do
        key = CacheKeys::Review.by_book(123)
        expect(key).to eq('book_review:review:by_book:book_id=123:origin=api')
      end
    end

    describe '.by_score' do
      it 'generates correct cache key for reviews by score range' do
        key = CacheKeys::Review.by_score(min_score: 3, max_score: 5)
        expect(key).to eq('book_review:review:by_score:min=3:max=5:origin=api')
      end

      it 'uses default max_score when not provided' do
        key = CacheKeys::Review.by_score(min_score: 4)
        expect(key).to eq('book_review:review:by_score:min=4:max=5:origin=api')
      end
    end

    describe '.high_rated' do
      it 'generates correct cache key for high-rated reviews' do
        key = CacheKeys::Review.high_rated
        expect(key).to eq('book_review:review:high_rated:origin=api')
      end
    end

    describe '.low_rated' do
      it 'generates correct cache key for low-rated reviews' do
        key = CacheKeys::Review.low_rated
        expect(key).to eq('book_review:review:low_rated:origin=api')
      end
    end

    describe '.recent' do
      it 'generates correct cache key for recent reviews' do
        key = CacheKeys::Review.recent(limit: 5)
        expect(key).to eq('book_review:review:recent:limit=5:origin=api')
      end

      it 'uses default limit when not provided' do
        key = CacheKeys::Review.recent
        expect(key).to eq('book_review:review:recent:limit=10:origin=api')
      end
    end

    describe '.for_books' do
      it 'generates correct cache key for reviews for multiple books' do
        key = CacheKeys::Review.for_books([ 3, 1, 2 ])
        expect(key).to eq('book_review:review:for_books:ids=1,2,3:origin=api')
      end

      it 'sorts book IDs consistently' do
        key1 = CacheKeys::Review.for_books([ 3, 1, 2 ])
        key2 = CacheKeys::Review.for_books([ 1, 2, 3 ])
        expect(key1).to eq(key2)
      end
    end

    describe '.pattern' do
      it 'generates correct pattern for all review cache keys' do
        pattern = CacheKeys::Review.pattern
        expect(pattern).to eq('book_review:review:*')
      end
    end

    describe '.pattern_for_review' do
      it 'generates correct pattern for specific review cache keys' do
        pattern = CacheKeys::Review.pattern_for_review(123)
        expect(pattern).to eq('book_review:review:*:id=123:*')
      end
    end

    describe '.pattern_for_book' do
      it 'generates correct pattern for reviews by book cache keys' do
        pattern = CacheKeys::Review.pattern_for_book(456)
        expect(pattern).to eq('book_review:review:*:book_id=456:*')
      end
    end

    describe '.search_pattern' do
      it 'generates correct pattern for search cache keys' do
        pattern = CacheKeys::Review.search_pattern
        expect(pattern).to eq('book_review:review:search:*')
      end
    end
  end
end
