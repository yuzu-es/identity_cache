# IdentityCache changelog

#### 0.2.6 (unreleased)

- Raise when trying to cache a through association. Previously it wouldn't be invalidated properly.
- Raise if a class method is called on a scope.  Previously the scope was ignored.

#### 0.2.5

- Fixed support for namespaced model classes
- Added some deduplication for parent cache expiry
- Fixed some deprecation warnings in rails 4.2

#### 0.2.4

- Refactoring, documentation and test changes

#### 0.2.3

- PostgreSQL support
- Rails 4.2 compatibility
- Fix: Don't connect to database when calling `IdentityCache.should_use_cache?`
- Fix: Fix invalid parent cache invalidation if object is embedded in different parents

#### 0.2.2

- Change: memcached is no longer a runtime dependency
- Use cache for read-only models.

#### 0.2.1

- Add a fallback backend using local memory.

#### 0.2.0

- Memcache CAS support

#### 0.1.0

- Backwards incompatible change: Stop expiring cache on after_touch callback.
- Change: fetch_multi accepts an array of keys as argument
- Change: :embed option value from false to :ids for cache_has_many for clarity
- Fix: Consistently use ActiveRecord / Arel APIs to build SQL queries
- Fix: `SystemStackError` when fetching more records than the max stack size
- Fix: Bug in `fetch_multi` in a transaction where results weren't compacted.
- Fix: Avoid unused preload on fetch_multi with :includes option for cache miss
- Fix: reload will invalidate the local instance cache

#### 0.0.7

- Add support for non-integer primary keys
- Fix: Not implemented error for cache_has_one with embed: false
- Fix: cache key to change when adding a cache_has_many association with :embed => false
- Fix: Compatibility rails 4.1 for `quote_value`, which needs default column.

#### 0.0.6

- Fix: bug where previously nil-cached attribute caches weren't expired on record creation
- Fix: cache key to not change when adding a non-embedded association.
- Perf: Rails 4 Only create `CollectionProxy` when using it

#### 0.0.5


#### 0.0.4

- Fix: only marshal attributes, embedded associations and normalized association IDs
- Add cache version number to cache keys
- Add test case to ensure version number is updated when the marshalled format changes

#### 0.0.3

- Fix: memoization for multi hits actually work
- Fix: quotes `SELECT` projection elements on cache misses
- Add CPU performance benchmark
- Fix: table names are not hardcoded anymore
- Logger now differentiates memoized vs non memoized hits

#### 0.0.2

- Fix: Existent embedded entries will no longer raise when `ActiveModel::MissingAttributeError` when accessing a newly created attribute.
- Fix: Do not marshal raw ActiveRecord associations
