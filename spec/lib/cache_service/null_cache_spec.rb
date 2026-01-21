require 'rails_helper'

RSpec.describe CacheService::NullCache do
  let(:null_cache) { described_class.new }

  describe '#fetch' do
    it 'always executes the block and returns its result' do
      result = null_cache.fetch('test_key', expires_in: 1.hour) { 'test_value' }
      expect(result).to eq('test_value')
    end

    it 'ignores the key parameter' do
      result1 = null_cache.fetch('key1') { 'value1' }
      result2 = null_cache.fetch('key2') { 'value2' }
      expect(result1).to eq('value1')
      expect(result2).to eq('value2')
    end

    it 'ignores the expires_in parameter' do
      result = null_cache.fetch('test_key', expires_in: 1.hour) { 'test_value' }
      expect(result).to eq('test_value')
    end

    it 'always executes the block even for the same key' do
      call_count = 0

      null_cache.fetch('same_key') { call_count += 1; 'value1' }
      null_cache.fetch('same_key') { call_count += 1; 'value2' }

      expect(call_count).to eq(2)
    end
  end

  describe '#write' do
    it 'always returns true' do
      result = null_cache.write('test_key', 'test_value', expires_in: 1.hour)
      expect(result).to be true
    end

    it 'ignores all parameters' do
      result1 = null_cache.write('key1', 'value1')
      result2 = null_cache.write('key2', 'value2', expires_in: 1.hour)
      expect(result1).to be true
      expect(result2).to be true
    end
  end

  describe '#read' do
    it 'always returns nil' do
      result = null_cache.read('test_key')
      expect(result).to be_nil
    end

    it 'ignores the key parameter' do
      result1 = null_cache.read('key1')
      result2 = null_cache.read('key2')
      expect(result1).to be_nil
      expect(result2).to be_nil
    end
  end

  describe '#delete' do
    it 'always returns true' do
      result = null_cache.delete('test_key')
      expect(result).to be true
    end

    it 'ignores the key parameter' do
      result1 = null_cache.delete('key1')
      result2 = null_cache.delete('key2')
      expect(result1).to be true
      expect(result2).to be true
    end
  end

  describe '#clear' do
    it 'always returns true' do
      result = null_cache.clear
      expect(result).to be true
    end
  end

  describe '#keys' do
    it 'always returns empty array' do
      result = null_cache.keys
      expect(result).to eq([])
    end

    it 'ignores the pattern parameter' do
      result1 = null_cache.keys('pattern1')
      result2 = null_cache.keys('pattern2')
      expect(result1).to eq([])
      expect(result2).to eq([])
    end
  end

  describe '#delete_many' do
    it 'always returns 0' do
      result = null_cache.delete_many([ 'key1', 'key2' ])
      expect(result).to eq(0)
    end

    it 'ignores the keys parameter' do
      result1 = null_cache.delete_many([ 'key1' ])
      result2 = null_cache.delete_many([ 'key1', 'key2', 'key3' ])
      expect(result1).to eq(0)
      expect(result2).to eq(0)
    end
  end

  describe '#exists?' do
    it 'always returns false' do
      result = null_cache.exists?('test_key')
      expect(result).to be false
    end

    it 'ignores the key parameter' do
      result1 = null_cache.exists?('key1')
      result2 = null_cache.exists?('key2')
      expect(result1).to be false
      expect(result2).to be false
    end
  end

  describe '#size' do
    it 'always returns 0' do
      result = null_cache.size
      expect(result).to eq(0)
    end
  end

  describe 'integration with CacheService' do
    it 'works with CacheService.fetch when configured' do
      # Mock CacheService to use NullCache
      allow(CacheService).to receive(:backend).and_return(null_cache)

      call_count = 0

      result1 = CacheService.fetch('test_key', expires_in: 1.hour) { call_count += 1; 'value1' }
      result2 = CacheService.fetch('test_key', expires_in: 1.hour) { call_count += 1; 'value2' }

      expect(result1).to eq('value1')
      expect(result2).to eq('value2')
      expect(call_count).to eq(2) # Both calls executed the block
    end
  end
end
