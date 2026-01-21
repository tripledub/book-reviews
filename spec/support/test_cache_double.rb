# frozen_string_literal: true

# Test double for CacheService backend
# This allows us to control the behavior of cache operations in tests
class TestCacheDouble < CacheService::Base
  def initialize
    @store = {}
    @keys_responses = {}
    @delete_responses = {}
  end

  def get(key)
    @store[key]
  end

  def set(key, value, expires_in: nil)
    @store[key] = value
    true
  end

  def delete(keys)
    keys = [ keys ] unless keys.is_a?(Array)
    deleted_count = 0

    keys.each do |key|
      if @store.key?(key)
        @store.delete(key)
        deleted_count += 1
      end
    end

    # For testing purposes, if no keys were actually deleted but we have a stub response, use it
    if deleted_count == 0 && @delete_responses.key?(keys)
      @delete_responses[keys]
    else
      deleted_count
    end
  end

  def exists?(key)
    @store.key?(key)
  end

  def clear
    @store.clear
    true
  end

  def stats
    { total_keys: @store.size, backend: "TestCacheDouble" }
  end

  def keys(pattern = "*")
    # Allow tests to control what keys() returns
    @keys_responses[pattern] || []
  end

  # Test helper methods
  def stub_keys_response(pattern, keys)
    @keys_responses[pattern] = keys
  end

  def stub_delete_response(keys, count)
    @delete_responses[keys] = count
  end
end
