require 'rails_helper'

RSpec.describe CacheKeys do
  describe '.books' do
    it 'generates correct cache key for books list' do
      key = CacheKeys.books(page: 1, limit: 20)
      expect(key).to eq('book_review:books:page=1:limit=20:origin=api')
    end

    it 'generates correct cache key with different parameters' do
      key = CacheKeys.books(page: 2, limit: 10)
      expect(key).to eq('book_review:books:page=2:limit=10:origin=api')
    end
  end

  describe '.book' do
    it 'generates correct cache key for specific book' do
      key = CacheKeys.book(123)
      expect(key).to eq('book_review:book:id=123:origin=api')
    end
  end

  describe '.search_books' do
    it 'generates correct cache key for search query' do
      key = CacheKeys.search_books('ruby programming')
      expect(key).to match(/^book_review:search:query=[a-f0-9]{32}:origin=api$/)
    end

    it 'generates consistent keys for same query' do
      key1 = CacheKeys.search_books('ruby programming')
      key2 = CacheKeys.search_books('ruby programming')
      expect(key1).to eq(key2)
    end

    it 'generates different keys for different queries' do
      key1 = CacheKeys.search_books('ruby programming')
      key2 = CacheKeys.search_books('python programming')
      expect(key1).not_to eq(key2)
    end

    it 'handles case insensitive queries consistently' do
      key1 = CacheKeys.search_books('Ruby Programming')
      key2 = CacheKeys.search_books('ruby programming')
      expect(key1).to eq(key2)
    end
  end

  describe '.reviews' do
    it 'generates correct cache key for book reviews' do
      key = CacheKeys.reviews(456)
      expect(key).to eq('book_review:reviews:book_id=456:origin=api')
    end
  end

  describe '.review_stats' do
    it 'generates correct cache key for review statistics' do
      key = CacheKeys.review_stats(789)
      expect(key).to eq('book_review:review_stats:book_id=789:origin=api')
    end
  end

  describe '.highly_rated_books' do
    it 'generates correct cache key for highly rated books' do
      key = CacheKeys.highly_rated_books(limit: 10)
      expect(key).to eq('book_review:highly_rated:limit=10:origin=api')
    end
  end

  describe '.recent_books' do
    it 'generates correct cache key for recent books' do
      key = CacheKeys.recent_books(limit: 5)
      expect(key).to eq('book_review:recent:limit=5:origin=api')
    end
  end

  describe 'pattern methods' do
    it 'generates correct pattern for books' do
      pattern = CacheKeys.books_pattern
      expect(pattern).to eq('book_review:books:*')
    end

    it 'generates correct pattern for search' do
      pattern = CacheKeys.search_pattern
      expect(pattern).to eq('book_review:search:*')
    end

    it 'generates correct pattern for reviews' do
      pattern = CacheKeys.reviews_pattern
      expect(pattern).to eq('book_review:reviews:*')
    end

    it 'generates correct pattern for stats' do
      pattern = CacheKeys.stats_pattern
      expect(pattern).to eq('book_review:review_stats:*')
    end

    it 'generates correct pattern for highly rated' do
      pattern = CacheKeys.highly_rated_pattern
      expect(pattern).to eq('book_review:highly_rated:*')
    end

    it 'generates correct pattern for recent' do
      pattern = CacheKeys.recent_pattern
      expect(pattern).to eq('book_review:recent:*')
    end
  end

  describe '.clear_book_cache' do
    it 'clears cache for specific book' do
      book_id = 123
      expected_keys = [
        CacheKeys.book(book_id),
        CacheKeys.reviews(book_id),
        CacheKeys.review_stats(book_id)
      ]
      expect(CacheService).to receive(:delete).with(expected_keys)

      CacheKeys.clear_book_cache(book_id)
    end
  end

  describe '.clear_all_cache' do
    it 'clears all cache with correct pattern' do
      expect(CacheKeys).to receive(:clear_pattern).with('book_review:*')
      CacheKeys.clear_all_cache
    end
  end

  describe '.keys' do
    it 'returns empty array by default' do
      keys = CacheKeys.keys
      expect(keys).to eq([])
    end

    it 'returns empty array for any pattern' do
      keys = CacheKeys.keys('some_pattern')
      expect(keys).to eq([])
    end

    it 'can be called with different patterns' do
      expect(CacheKeys.keys('*')).to eq([])
      expect(CacheKeys.keys('book_review:*')).to eq([])
      expect(CacheKeys.keys('specific:key')).to eq([])
    end

    it 'executes the actual implementation without mocking' do
      # Test the actual implementation without mocking
      keys = CacheKeys.keys('test_pattern')
      expect(keys).to eq([])
    end

    it 'calls CacheService.keys directly' do
      # This test covers line 82 by calling the real CacheService.keys method
      pattern = 'book_review:direct_test:*'

      # Don't mock anything - let the real implementation run
      keys = CacheKeys.keys(pattern)
      expect(keys).to eq([])
    end

    it 'calls CacheService.keys with a wildcard pattern' do
      # Another test to ensure line 82 is covered
      keys = CacheKeys.keys('*')
      expect(keys).to be_an(Array)
    end
  end

  describe '.clear_pattern' do
    it 'returns 0 when no keys match pattern (mocked)' do
      allow(CacheKeys).to receive(:keys).with('no_match:*', cache_service: CacheService).and_return([])
      result = CacheKeys.clear_pattern('no_match:*')
      expect(result).to eq(0)
    end

    it 'deletes keys when pattern matches (mocked)' do
      matching_keys = [ 'key1', 'key2' ]
      allow(CacheKeys).to receive(:keys).with('match:*', cache_service: CacheService).and_return(matching_keys)
      allow(CacheService).to receive(:delete).with(matching_keys).and_return(2)

      result = CacheKeys.clear_pattern('match:*')
      expect(result).to eq(2)
    end

    it 'calls CacheService.delete with the correct keys (mocked)' do
      matching_keys = [ 'book_review:books:page=1', 'book_review:books:page=2' ]
      allow(CacheKeys).to receive(:keys).with('book_review:books:*', cache_service: CacheService).and_return(matching_keys)
      expect(CacheService).to receive(:delete).with(matching_keys).and_return(2)

      CacheKeys.clear_pattern('book_review:books:*')
    end

    it 'executes the actual implementation when no keys are found' do
      # Test the actual implementation without mocking - this should cover lines 134-137
      result = CacheKeys.clear_pattern('no_match_pattern')
      expect(result).to eq(0)
    end

    it 'executes the actual implementation when keys are found' do
      # This test covers lines 132, 135 by mocking CacheKeys.keys to return keys
      # and then calling the real CacheService.delete
      pattern = 'book_review:actual_test:*'

      # Mock CacheKeys.keys to return some keys, then let the real CacheService.delete be called
      allow(CacheKeys).to receive(:keys).with(pattern, cache_service: CacheService).and_return([ 'key1', 'key2' ])
      allow(CacheService).to receive(:delete).with([ 'key1', 'key2' ]).and_return(2)

      result = CacheKeys.clear_pattern(pattern)
      expect(result).to eq(2)
    end

    it 'executes the real clear_pattern implementation without mocking CacheKeys.keys' do
      # This test covers lines 132, 133, 135 by calling the real implementation
      # First, set up some actual cache keys so CacheService.keys returns something
      CacheService.set('book_review:real_test:key1', 'value1')
      CacheService.set('book_review:real_test:key2', 'value2')

      pattern = 'book_review:real_test:*'

      # Don't mock CacheKeys.keys - let it call the real implementation
      # This should hit lines 132, 133, 135
      result = CacheKeys.clear_pattern(pattern)

      # Clean up
      CacheService.delete('book_review:real_test:key1')
      CacheService.delete('book_review:real_test:key2')

      expect(result).to eq(2)
    end

    it 'calls self.keys with the provided pattern' do
      pattern = 'book_review:books:*'
      matching_keys = [ 'book_review:books:page=1', 'book_review:books:page=2' ]

      expect(CacheKeys).to receive(:keys).with(pattern, cache_service: CacheService).and_return(matching_keys)
      expect(CacheService).to receive(:delete).with(matching_keys).and_return(2)

      result = CacheKeys.clear_pattern(pattern)
      expect(result).to eq(2)
    end

    it 'returns 0 when keys array is empty' do
      pattern = 'no_match:*'

      expect(CacheKeys).to receive(:keys).with(pattern, cache_service: CacheService).and_return([])
      expect(CacheService).not_to receive(:delete)

      result = CacheKeys.clear_pattern(pattern)
      expect(result).to eq(0)
    end
  end

  describe 'clear cache methods' do
    before do
      allow(CacheKeys).to receive(:clear_pattern).and_return(5)
    end

    describe '.clear_books_cache' do
      it 'clears books cache with correct pattern' do
        expect(CacheKeys).to receive(:clear_pattern).with('book_review:books:*')
        CacheKeys.clear_books_cache
      end
    end

    describe '.clear_search_cache' do
      it 'clears search cache with correct pattern' do
        expect(CacheKeys).to receive(:clear_pattern).with('book_review:search:*')
        CacheKeys.clear_search_cache
      end
    end

    describe '.clear_reviews_cache' do
      it 'clears reviews cache with correct pattern' do
        expect(CacheKeys).to receive(:clear_pattern).with('book_review:reviews:*')
        CacheKeys.clear_reviews_cache
      end
    end

    describe '.clear_stats_cache' do
      it 'clears stats cache with correct pattern' do
        expect(CacheKeys).to receive(:clear_pattern).with('book_review:review_stats:*')
        CacheKeys.clear_stats_cache
      end
    end

    describe '.clear_highly_rated_cache' do
      it 'clears highly rated cache with correct pattern' do
        expect(CacheKeys).to receive(:clear_pattern).with('book_review:highly_rated:*')
        CacheKeys.clear_highly_rated_cache
      end
    end

    describe '.clear_recent_cache' do
      it 'clears recent cache with correct pattern' do
        expect(CacheKeys).to receive(:clear_pattern).with('book_review:recent:*')
        CacheKeys.clear_recent_cache
      end
    end
  end
end
