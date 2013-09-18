module IdentityCache
  BACKEND_KEY = 'idc:backend:key'

  class CacheEntry
    DELETED = 'D'

    def initialize(key, value, cas = nil)
      @key, @value, @cas = key, value, cas
    end

    def exists?
      !@value.nil? && @value != DELETED
    end

    def value
      @value == IdentityCache::CACHED_NIL ? nil : @value
    end

    def value=(v)
      @value = v.nil? ? IdentityCache::CACHED_NIL : v
    end

    def save
      if @cas.nil?
        self.class.backend.add(@key, @value)
      else
        self.class.backend.cas(@key, @value, @cas)
      end
    end

    def self.find(key)
      value, cas = backend.get(key)
      CacheEntry.new(key, value, cas)
    end

    def self.delete(key)
      backend.set(key, DELETED, 10)
    end

    def self.backend
      Thread.current[IdentityCache::BACKEND_KEY] || IdentityCache.cache_backend
    end
  end
end
