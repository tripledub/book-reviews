require 'rails_helper'
require_relative '../support/test_cache_double'

RSpec.describe 'CacheKeys Integration Tests' do
  let(:test_cache) { TestCacheDouble.new }

  before do
    # Temporarily replace the CacheService backend with our test double
    @original_backend = CacheService.backend
    CacheService.backend = test_cache

    # Store the original method implementations before they get overridden
    @original_keys_method = CacheKeys.method(:keys)
    @original_clear_pattern_method = CacheKeys.method(:clear_pattern)
  end

  after do
    # Restore the original backend and methods
    CacheService.backend = @original_backend
  end

  describe 'original CacheKeys implementation' do
    it 'calls CacheService.keys with the provided pattern' do
      # This should hit line 82 in the original implementation
      pattern = 'book_review:test:*'
      test_cache.stub_keys_response(pattern, [ 'key1', 'key2' ])

      # Call the original implementation directly (before initializer override)
      result = @original_keys_method.call(pattern)
      expect(result).to eq([ 'key1', 'key2' ])
    end

    it 'executes clear_pattern with non-empty keys' do
      # This should hit lines 132, 135 in the original implementation
      pattern = 'book_review:test:*'
      test_cache.stub_keys_response(pattern, [ 'key1', 'key2' ])
      test_cache.stub_delete_response([ 'key1', 'key2' ], 2)

      # Call the original implementation directly
      result = @original_clear_pattern_method.call(pattern)
      expect(result).to eq(2)
    end

    it 'executes clear_pattern with empty keys' do
      # This should hit line 133 in the original implementation
      pattern = 'book_review:empty:*'
      test_cache.stub_keys_response(pattern, [])

      # Call the original implementation directly
      result = @original_clear_pattern_method.call(pattern)
      expect(result).to eq(0)
    end
  end
end
