require 'rails_helper'

RSpec.describe CacheService do
  let(:test_key) { 'test_key' }
  let(:test_value) { { 'data' => 'test' } }

  before do
    # Clear cache before each test
    CacheService.clear
  end

  describe '.fetch' do
    context 'when cache miss' do
      it 'executes block and caches result' do
        result = CacheService.fetch(test_key, expires_in: 1.hour) do
          test_value
        end

        expect(result).to eq(test_value)
        expect(CacheService.get(test_key)).to eq(test_value)
      end

      it 'logs cache miss' do
        expect(Rails.logger).to receive(:info).with("[CacheService] Cache miss for key: #{test_key}")

        CacheService.fetch(test_key) { test_value }
      end

      it 'handles block returning nil' do
        result = CacheService.fetch(test_key) { nil }
        expect(result).to be_nil
        # Should not cache nil values
        expect(CacheService.get(test_key)).to be_nil
      end

      it 'handles block returning false' do
        result = CacheService.fetch(test_key) { false }
        expect(result).to be false
        # Should not cache false values
        expect(CacheService.get(test_key)).to be_nil
      end
    end

    context 'when cache hit' do
      before do
        CacheService.set(test_key, test_value)
      end

      it 'returns cached value without executing block' do
        block_executed = false

        result = CacheService.fetch(test_key) do
          block_executed = true
          'new_value'
        end

        expect(result).to eq(test_value)
        expect(block_executed).to be false
      end

      it 'logs cache hit' do
        expect(Rails.logger).to receive(:info).with("[CacheService] Cache hit for key: #{test_key}")

        CacheService.fetch(test_key) { 'new_value' }
      end
    end

    it 'requires block' do
      expect { CacheService.fetch(test_key) }.to raise_error(ArgumentError, 'Block required for fetch operation')
    end
  end

  describe '.get' do
    it 'returns nil for non-existent key' do
      expect(CacheService.get('non_existent')).to be_nil
    end

    it 'returns cached value' do
      CacheService.set(test_key, test_value)
      expect(CacheService.get(test_key)).to eq(test_value)
    end
  end

  describe '.set' do
    it 'stores value in cache' do
      CacheService.set(test_key, test_value)
      expect(CacheService.get(test_key)).to eq(test_value)
    end

    it 'returns true on success' do
      result = CacheService.set(test_key, test_value)
      expect(result).to be true
    end
  end

  describe '.delete' do
    it 'deletes single key' do
      CacheService.set(test_key, test_value)
      expect(CacheService.delete(test_key)).to eq(1)
      expect(CacheService.get(test_key)).to be_nil
    end

    it 'deletes multiple keys' do
      CacheService.set('key1', 'value1')
      CacheService.set('key2', 'value2')
      CacheService.set('key3', 'value3')

      expect(CacheService.delete([ 'key1', 'key2' ])).to eq(2)
      expect(CacheService.get('key1')).to be_nil
      expect(CacheService.get('key2')).to be_nil
      expect(CacheService.get('key3')).to eq('value3')
    end

    it 'returns 0 for non-existent keys' do
      expect(CacheService.delete('non_existent')).to eq(0)
    end
  end

  describe '.exists?' do
    it 'returns false for non-existent key' do
      expect(CacheService.exists?('non_existent')).to be false
    end

    it 'returns true for existing key' do
      CacheService.set(test_key, test_value)
      expect(CacheService.exists?(test_key)).to be true
    end
  end

  describe '.clear' do
    it 'clears all cache' do
      CacheService.set('key1', 'value1')
      CacheService.set('key2', 'value2')

      expect(CacheService.clear).to be true
      expect(CacheService.get('key1')).to be_nil
      expect(CacheService.get('key2')).to be_nil
    end
  end

  describe '.keys' do
    it 'returns all keys when no pattern specified' do
      CacheService.set('key1', 'value1')
      CacheService.set('key2', 'value2')

      keys = CacheService.keys
      expect(keys).to contain_exactly('key1', 'key2')
    end

    it 'returns matching keys with pattern' do
      CacheService.set('book_review:books:page=1', 'value1')
      CacheService.set('book_review:books:page=2', 'value2')
      CacheService.set('book_review:search:query=abc', 'value3')

      keys = CacheService.keys('book_review:books:*')
      expect(keys).to contain_exactly('book_review:books:page=1', 'book_review:books:page=2')
    end

    it 'returns empty array when no keys match pattern' do
      CacheService.set('key1', 'value1')
      CacheService.set('key2', 'value2')

      keys = CacheService.keys('nonexistent:*')
      expect(keys).to be_empty
    end
  end

  describe '.stats' do
    it 'returns cache statistics' do
      CacheService.set('key1', 'value1')
      CacheService.set('key2', 'value2')

      stats = CacheService.stats
      expect(stats).to include(:total_keys, :backend)
      expect(stats[:total_keys]).to eq(2)
    end
  end

  describe '.configure' do
    it 'configures backend' do
      expect(CacheService.backend).to be_a(CacheService::MemoryCache)
    end
  end
end
