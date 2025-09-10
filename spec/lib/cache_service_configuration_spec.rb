require 'rails_helper'

RSpec.describe 'CacheService Configuration' do
  describe 'environment-based configuration' do
    it 'uses memory cache by default in development' do
      expect(CacheService.backend).to be_a(CacheService::MemoryCache)
    end

    it 'can be overridden with environment variables' do
      # This test would need to be run with BOOK_REVIEW_CACHE_BACKEND=file
      # to actually test the override, but we can test the configuration exists
      expect(Rails.application.config.book_review_cache_backend).to be_in([ :memory, :file, :redis ])
      expect(Rails.application.config.book_review_cache_options).to be_a(Hash)
    end

    it 'has proper configuration in each environment' do
      case Rails.env
      when 'development'
        expect(Rails.application.config.book_review_cache_backend).to eq(:memory)
      when 'test'
        expect(Rails.application.config.book_review_cache_backend).to eq(:memory)
      when 'production'
        expect(Rails.application.config.book_review_cache_backend).to eq(:file)
      end
    end
  end

  describe 'cache backend selection' do
    it 'configures memory cache correctly' do
      # Test that memory cache is properly configured
      expect(CacheService.backend).to respond_to(:get)
      expect(CacheService.backend).to respond_to(:set)
      expect(CacheService.backend).to respond_to(:delete)
      expect(CacheService.backend).to respond_to(:exists?)
      expect(CacheService.backend).to respond_to(:clear)
      expect(CacheService.backend).to respond_to(:stats)
      expect(CacheService.backend).to respond_to(:keys)
    end
  end
end
