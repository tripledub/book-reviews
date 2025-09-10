require 'rails_helper'

RSpec.describe CacheService::MemoryCache do
  let(:cache) { CacheService::MemoryCache.new }
  let(:test_key) { 'test_key' }
  let(:test_value) { { 'data' => 'test' } }

  before do
    cache.clear
  end

  describe '#get' do
    it 'returns nil for non-existent key' do
      expect(cache.get('non_existent')).to be_nil
    end

    it 'returns cached value' do
      cache.set(test_key, test_value)
      expect(cache.get(test_key)).to eq(test_value)
    end

    it 'returns nil for expired key' do
      cache.set(test_key, test_value, expires_in: 1)
      sleep(1.1) # Wait for expiration
      expect(cache.get(test_key)).to be_nil
    end
  end

  describe '#set' do
    it 'stores value in cache' do
      cache.set(test_key, test_value)
      expect(cache.get(test_key)).to eq(test_value)
    end

    it 'returns true on success' do
      result = cache.set(test_key, test_value)
      expect(result).to be true
    end

    it 'handles expiration' do
      # Set with 1 second expiration
      cache.set(test_key, test_value, expires_in: 1)

      # Should be available immediately
      expect(cache.get(test_key)).to eq(test_value)

      # Wait for expiration
      sleep(1.1)
      expect(cache.get(test_key)).to be_nil
    end
  end

  describe '#delete' do
    it 'deletes single key' do
      cache.set(test_key, test_value)
      expect(cache.delete([ test_key ])).to eq(1)
      expect(cache.get(test_key)).to be_nil
    end

    it 'deletes multiple keys' do
      cache.set('key1', 'value1')
      cache.set('key2', 'value2')
      cache.set('key3', 'value3')

      expect(cache.delete([ 'key1', 'key2' ])).to eq(2)
      expect(cache.get('key1')).to be_nil
      expect(cache.get('key2')).to be_nil
      expect(cache.get('key3')).to eq('value3')
    end

    it 'returns 0 for non-existent keys' do
      expect(cache.delete([ 'non_existent' ])).to eq(0)
    end
  end

  describe '#exists?' do
    it 'returns false for non-existent key' do
      expect(cache.exists?('non_existent')).to be false
    end

    it 'returns true for existing key' do
      cache.set(test_key, test_value)
      expect(cache.exists?(test_key)).to be true
    end

    it 'returns false for expired key' do
      cache.set(test_key, test_value, expires_in: 1)
      sleep(1.1) # Wait for expiration
      expect(cache.exists?(test_key)).to be false
    end
  end

  describe '#clear' do
    it 'clears all cache' do
      cache.set('key1', 'value1')
      cache.set('key2', 'value2')

      expect(cache.clear).to be true
      expect(cache.get('key1')).to be_nil
      expect(cache.get('key2')).to be_nil
    end
  end

  describe '#stats' do
    it 'returns cache statistics' do
      cache.set('key1', 'value1')
      cache.set('key2', 'value2')

      stats = cache.stats
      expect(stats).to include(:total_keys, :expired_keys, :memory_usage, :backend)
      expect(stats[:total_keys]).to eq(2)
      expect(stats[:backend]).to eq('MemoryCache')
    end

    it 'cleans up expired keys when generating stats' do
      cache.set('key1', 'value1', expires_in: 1)
      cache.set('key2', 'value2')

      sleep(1.1) # Wait for expiration

      stats = cache.stats
      expect(stats[:total_keys]).to eq(1)
      expect(stats[:expired_keys]).to eq(1)
    end
  end

  describe '#keys' do
    it 'returns all keys when no pattern specified' do
      cache.set('key1', 'value1')
      cache.set('key2', 'value2')

      keys = cache.keys
      expect(keys).to contain_exactly('key1', 'key2')
    end

    it 'returns matching keys with pattern' do
      cache.set('book_review:books:page=1', 'value1')
      cache.set('book_review:books:page=2', 'value2')
      cache.set('book_review:search:query=abc', 'value3')

      keys = cache.keys('book_review:books:*')
      expect(keys).to contain_exactly('book_review:books:page=1', 'book_review:books:page=2')
    end

    it 'cleans up expired keys when searching' do
      cache.set('key1', 'value1', expires_in: 1)
      cache.set('key2', 'value2')

      sleep(1.1) # Wait for expiration

      keys = cache.keys
      expect(keys).to contain_exactly('key2')
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access safely' do
      threads = []

      # Create multiple threads that set and get values
      10.times do |i|
        threads << Thread.new do
          cache.set("key#{i}", "value#{i}")
          expect(cache.get("key#{i}")).to eq("value#{i}")
        end
      end

      threads.each(&:join)

      # Verify all values are still accessible
      10.times do |i|
        expect(cache.get("key#{i}")).to eq("value#{i}")
      end
    end
  end
end
