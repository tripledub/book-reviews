require 'rails_helper'
require_relative '../support/test_cache_double'

RSpec.describe 'CacheKeys with Dependency Injection' do
  let(:test_cache) { TestCacheDouble.new }

  describe '.keys' do
    it 'calls the injected cache service with the pattern' do
      pattern = 'book_review:test:*'
      test_cache.stub_keys_response(pattern, [ 'key1', 'key2' ])

      result = CacheKeys.keys(pattern, cache_service: test_cache)
      expect(result).to eq([ 'key1', 'key2' ])
    end

    it 'uses CacheService by default when no cache_service provided' do
      # This should work with the configured CacheService
      result = CacheKeys.keys('*')
      expect(result).to be_an(Array)
    end
  end

  describe '.clear_pattern' do
    it 'executes the full clear pattern flow with injected cache service' do
      pattern = 'book_review:test:*'
      test_cache.stub_keys_response(pattern, [ 'key1', 'key2' ])
      test_cache.stub_delete_response([ 'key1', 'key2' ], 2)

      result = CacheKeys.clear_pattern(pattern, cache_service: test_cache)
      expect(result).to eq(2)
    end

    it 'returns 0 when no keys match pattern' do
      pattern = 'book_review:empty:*'
      test_cache.stub_keys_response(pattern, [])

      result = CacheKeys.clear_pattern(pattern, cache_service: test_cache)
      expect(result).to eq(0)
    end

    it 'uses CacheService by default when no cache_service provided' do
      # This should work with the configured CacheService
      result = CacheKeys.clear_pattern('no_match_pattern')
      expect(result).to eq(0)
    end
  end
end
