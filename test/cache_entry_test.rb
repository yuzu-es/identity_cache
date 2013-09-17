require 'test_helper'

class CacheEntryTest < IdentityCache::TestCase
  KEY = 'key'

  def setup
    super
    IdentityCache.cache_backend = IdentityCache::MemcachedAdapter.new("localhost:#{$memcached_port}")
  end
  
  def test_save
    entry = IdentityCache::CacheEntry.new(KEY, 'value')
    entry.save

    assert 'value', IdentityCache::CacheEntry.find(KEY).value
  end
end
