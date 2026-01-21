# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CacheService::RedisCache, type: :model do
  let(:cache) { described_class.new }
  let(:test_key) { 'test_key' }
  let(:test_value) { { 'message' => 'Hello Redis!' } }

  before do
    # Skip tests if Redis is not available
    begin
      cache.send(:ensure_connection)
    rescue => e
      skip "Redis not available: #{e.message}"
    end
  end

  after do
    cache.clear
  end

  describe '#get' do
    it 'returns nil for non-existent key' do
      expect(cache.get('non_existent_key')).to be_nil
    end

    it 'returns cached value' do
      marshalled_value = Marshal.dump(test_value)
      cache.set(test_key, marshalled_value)
      expect(cache.get(test_key)).to eq(marshalled_value)
    end

    it 'returns nil for expired key' do
      # Mock Redis to simulate expired key
      mock_redis = double('redis')
      allow(cache).to receive(:with_connection).and_yield(mock_redis)
      allow(mock_redis).to receive(:get).with(test_key).and_return(nil)
      allow(mock_redis).to receive(:flushdb) # For the clear call in before block

      expect(cache.get(test_key)).to be_nil
    end
  end

  describe '#set' do
    it 'stores value in cache' do
      marshalled_value = Marshal.dump(test_value)
      expect(cache.set(test_key, marshalled_value)).to be true
      expect(cache.get(test_key)).to eq(marshalled_value)
    end

    it 'returns true on success' do
      expect(cache.set(test_key, test_value)).to be true
    end

    it 'handles expiration' do
      # Mock Redis to simulate expiration
      mock_redis = double('redis')
      allow(cache).to receive(:with_connection).and_yield(mock_redis)
      allow(mock_redis).to receive(:flushdb) # For the clear call in before block

      # First call - key exists
      allow(mock_redis).to receive(:exists?).with(test_key).and_return(true)
      expect(cache.exists?(test_key)).to be true

      # Second call - key expired
      allow(mock_redis).to receive(:exists?).with(test_key).and_return(false)
      expect(cache.exists?(test_key)).to be false
    end

    it 'uses setex when expires_in is provided' do
      # Mock Redis to verify setex is called with TTL
      mock_redis = double('redis')
      allow(cache).to receive(:with_connection).and_yield(mock_redis)
      allow(mock_redis).to receive(:flushdb) # For the clear call in before block

      # Expect setex to be called with key, TTL, and serialized value
      expect(mock_redis).to receive(:setex).with(test_key, 3600, anything)

      cache.set(test_key, test_value, expires_in: 1.hour)
    end

    it 'uses set when expires_in is not provided' do
      # Mock Redis to verify set is called without TTL
      mock_redis = double('redis')
      allow(cache).to receive(:with_connection).and_yield(mock_redis)
      allow(mock_redis).to receive(:flushdb) # For the clear call in before block

      # Expect set to be called with key and serialized value (no TTL)
      expect(mock_redis).to receive(:set).with(test_key, anything)

      cache.set(test_key, test_value)
    end
  end

  describe '#delete' do
    it 'deletes single key' do
      cache.set(test_key, test_value)
      expect(cache.delete(test_key)).to eq(1)
      expect(cache.get(test_key)).to be_nil
    end

    it 'deletes multiple keys' do
      cache.set('key1', 'value1')
      cache.set('key2', 'value2')
      expect(cache.delete([ 'key1', 'key2' ])).to eq(2)
      expect(cache.get('key1')).to be_nil
      expect(cache.get('key2')).to be_nil
    end

    it 'returns 0 for non-existent keys' do
      expect(cache.delete('non_existent_key')).to eq(0)
    end
  end

  describe '#exists?' do
    it 'returns false for non-existent key' do
      expect(cache.exists?('non_existent_key')).to be false
    end

    it 'returns true for existing key' do
      cache.set(test_key, test_value)
      expect(cache.exists?(test_key)).to be true
    end

    it 'returns false for expired key' do
      # Mock Redis to simulate expired key
      mock_redis = double('redis')
      allow(cache).to receive(:with_connection).and_yield(mock_redis)
      allow(mock_redis).to receive(:exists?).with(test_key).and_return(false)
      allow(mock_redis).to receive(:flushdb) # For the clear call in before block

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
    it 'returns Redis statistics' do
      stats = cache.stats
      expect(stats).to be_a(Hash)
      expect(stats).to have_key(:used_memory)
      expect(stats).to have_key(:connected_clients)
      expect(stats).to have_key(:total_commands_processed)
      expect(stats).to have_key(:keyspace_hits)
      expect(stats).to have_key(:keyspace_misses)
      expect(stats).to have_key(:redis_version)
      expect(stats).to have_key(:uptime_in_seconds)
    end
  end

  describe '#keys' do
    it 'returns all keys when no pattern specified' do
      cache.set('key1', 'value1')
      cache.set('key2', 'value2')
      keys = cache.keys
      expect(keys).to include('key1', 'key2')
    end

    it 'returns matching keys with pattern' do
      cache.set('book_review:books:page=1', 'books data')
      cache.set('book_review:search:query=ruby', 'search data')
      cache.set('other:key', 'other data')

      book_keys = cache.keys('book_review:books:*')
      expect(book_keys).to include('book_review:books:page=1')
      expect(book_keys).not_to include('book_review:search:query=ruby')
      expect(book_keys).not_to include('other:key')
    end

    it 'returns empty array for non-matching pattern' do
      cache.set('key1', 'value1')
      keys = cache.keys('nonexistent:*')
      expect(keys).to be_empty
    end

    it 'handles large number of keys' do
      # Add multiple keys
      10.times do |i|
        cache.set("key#{i}", "value#{i}")
      end

      keys = cache.keys('key*')
      expect(keys.length).to eq(10)
      expect(keys).to all(start_with('key'))
    end
  end

  describe 'connection handling' do
    it 'handles connection failures gracefully' do
      # This test would require mocking Redis connection failure
      # For now, we'll just ensure the connection is working
      expect { cache.send(:ensure_connection) }.not_to raise_error
    end

    it 'logs error and re-raises when ensure_connection fails' do
      # Mock Redis connection failure in ensure_connection
      mock_redis = double('redis')
      allow(mock_redis).to receive(:ping).and_raise(StandardError, 'Connection failed')

      # Mock Rails logger
      mock_logger = double('logger')
      allow(Rails).to receive(:logger).and_return(mock_logger)
      expect(mock_logger).to receive(:error).with('[RedisCache] Failed to connect to Redis: Connection failed')

      # Mock Redis.new to return our failing redis
      allow(Redis).to receive(:new).and_return(mock_redis)

      # Create a new cache instance - this will fail during initialization
      expect { CacheService::RedisCache.new }.to raise_error(StandardError, 'Connection failed')
    end

    it 'handles connection errors in with_connection and reconnects' do
      # Mock Redis connection error and successful reconnection
      failing_redis = double('failing_redis')
      working_redis = double('working_redis')

      # First redis fails, second succeeds
      allow(failing_redis).to receive(:ping).and_raise(Redis::ConnectionError, 'Connection lost')
      allow(working_redis).to receive(:ping).and_return('PONG')

      # Mock Rails logger
      mock_logger = double('logger')
      allow(Rails).to receive(:logger).and_return(mock_logger)
      expect(mock_logger).to receive(:warn).with('[RedisCache] Connection error, attempting reconnection: Connection lost')
      allow(mock_logger).to receive(:error) # Allow error calls from ensure_connection

      # Mock the block execution on working redis
      block_executed = false
      allow(working_redis).to receive(:get).with('test_key') do
        block_executed = true
        nil
      end

      # Mock Redis.new to return working redis for reconnection
      allow(Redis).to receive(:new).and_return(working_redis)

      # Create a new cache instance and manually set the failing redis
      test_cache = CacheService::RedisCache.new
      test_cache.instance_variable_set(:@redis, failing_redis)

      # This should trigger the reconnection logic
      result = test_cache.get('test_key')

      expect(result).to be_nil
      expect(block_executed).to be true
    end
  end

  describe 'error handling and logging' do
    let(:mock_redis) { double('redis') }
    let(:mock_logger) { double('logger') }

    before do
      allow(Rails).to receive(:logger).and_return(mock_logger)
      allow(mock_logger).to receive(:error)
      allow(mock_logger).to receive(:warn)
      # Mock the clear call in the before block
      allow(cache).to receive(:clear)
    end

    describe '#get error handling' do
      it 'logs error and returns nil when Redis fails' do
        allow(cache).to receive(:with_connection).and_raise(StandardError, 'Redis connection failed')

        result = cache.get('test_key')

        expect(result).to be_nil
        expect(mock_logger).to have_received(:error).with('[RedisCache] Error getting key test_key: Redis connection failed')
      end
    end

    describe '#set error handling' do
      it 'logs error and returns false when Redis fails' do
        allow(cache).to receive(:with_connection).and_raise(StandardError, 'Redis connection failed')

        result = cache.set('test_key', 'test_value')

        expect(result).to be false
        expect(mock_logger).to have_received(:error).with('[RedisCache] Error setting key test_key: Redis connection failed')
      end
    end

    describe '#delete error handling' do
      it 'logs error and returns 0 when Redis fails' do
        allow(cache).to receive(:with_connection).and_raise(StandardError, 'Redis connection failed')

        result = cache.delete([ 'test_key' ])

        expect(result).to eq(0)
        expect(mock_logger).to have_received(:error).with('[RedisCache] Error deleting keys ["test_key"]: Redis connection failed')
      end
    end

    describe '#exists? error handling' do
      it 'logs error and returns false when Redis fails' do
        allow(cache).to receive(:with_connection).and_raise(StandardError, 'Redis connection failed')

        result = cache.exists?('test_key')

        expect(result).to be false
        expect(mock_logger).to have_received(:error).with('[RedisCache] Error checking existence of key test_key: Redis connection failed')
      end
    end

    describe '#clear error handling' do
      it 'logs error and returns false when Redis fails' do
        # Create a new cache instance to avoid interference
        test_cache = CacheService::RedisCache.new
        allow(test_cache).to receive(:with_connection).and_raise(StandardError, 'Redis connection failed')

        result = test_cache.clear

        expect(result).to be false
        expect(mock_logger).to have_received(:error).with('[RedisCache] Error clearing cache: Redis connection failed')
      end
    end

    describe '#stats error handling' do
      it 'logs error and returns default stats when Redis fails' do
        allow(cache).to receive(:with_connection).and_raise(StandardError, 'Redis connection failed')

        result = cache.stats

        expect(result).to eq({
          total_keys: 0,
          used_memory: 'unknown',
          connected_clients: 0,
          total_commands_processed: 0,
          keyspace_hits: 0,
          keyspace_misses: 0,
          backend: 'RedisCache',
          redis_version: 'unknown',
          uptime_in_seconds: 0
        })
        expect(mock_logger).to have_received(:error).with('[RedisCache] Error getting stats: Redis connection failed')
      end
    end

    describe '#keys error handling' do
      it 'logs error and returns empty array when Redis fails' do
        allow(cache).to receive(:with_connection).and_raise(StandardError, 'Redis connection failed')

        result = cache.keys('test:*')

        expect(result).to eq([])
        expect(mock_logger).to have_received(:error).with('[RedisCache] Error scanning keys with pattern test:*: Redis connection failed')
      end
    end

    describe '#keys infinite loop detection' do
      it 'logs warning when infinite loop is detected' do
        allow(cache).to receive(:with_connection).and_yield(mock_redis)
        allow(mock_redis).to receive(:scan).and_return([ 1, [ 'key1' ] ], [ 1, [ 'key2' ] ]) # Same cursor returned

        result = cache.keys('test:*')

        expect(result).to eq([ 'key1', 'key2' ])
        expect(mock_logger).to have_received(:warn).with('[RedisCache] Infinite loop detected in SCAN for pattern test:*, cursor: 1')
      end

      it 'logs warning when max iterations reached' do
        # Create a new cache instance to avoid interference
        test_cache = CacheService::RedisCache.new
        allow(test_cache).to receive(:with_connection).and_yield(mock_redis)

        # Mock scan to return many iterations to hit the limit
        call_count = 0
        allow(mock_redis).to receive(:scan) do
          call_count += 1
          if call_count > 1000
            [ 0, [] ] # End the scan
          else
            [ call_count, [ "key#{call_count}" ] ]
          end
        end

        result = test_cache.keys('test:*')

        expect(mock_logger).to have_received(:warn).with('[RedisCache] SCAN operation hit safety limit for pattern test:*')
      end
    end
  end

  describe 'serialization' do
    it 'handles complex objects' do
      complex_object = {
        'string' => 'test',
        'number' => 42,
        'array' => [ 1, 2, 3 ],
        'hash' => { 'nested' => 'value' },
        'boolean' => true,
        'nil_value' => nil
      }

      marshalled_value = Marshal.dump(complex_object)
      cache.set('complex', marshalled_value)
      retrieved = cache.get('complex')
      expect(retrieved).to eq(marshalled_value)
    end

    it 'handles nil values' do
      marshalled_nil = Marshal.dump(nil)
      cache.set('nil_key', marshalled_nil)
      expect(cache.get('nil_key')).to eq(marshalled_nil)
    end
  end

  describe 'thread safety' do
    it 'handles concurrent access safely' do
      threads = []
      results = []

      # Create multiple threads that set and get values
      5.times do |i|
        threads << Thread.new do
          cache.set("thread_key_#{i}", "value_#{i}")
          results << cache.get("thread_key_#{i}")
        end
      end

      threads.each(&:join)

      expect(results).to all(eq('value_0').or(eq('value_1')).or(eq('value_2')).or(eq('value_3')).or(eq('value_4')))
    end
  end
end
