require "test_helper"

class AttributeCacheTest < IdentityCache::TestCase
  NAMESPACE = IdentityCache::CacheKeyGeneration::DEFAULT_NAMESPACE

  def expect_find(key, value)
    entry = IdentityCache::CacheEntry.new(key, value, 0)
    IdentityCache::CacheEntry.expects(:find).with(key).returns(entry)
    entry
  end

  def setup
    super
    AssociatedRecord.cache_attribute :name
    AssociatedRecord.cache_attribute :record, :by => [:id, :name]

    @parent = Record.create!(:title => 'bob')
    @record = @parent.associated_records.create!(:name => 'foo')
    @name_attribute_key = "#{NAMESPACE}attribute:AssociatedRecord:name:id:#{cache_hash(@record.id.to_s)}"
    @blob_key = "#{NAMESPACE}blob:AssociatedRecord:#{cache_hash("id:integer,name:string,record_id:integer")}:1"
  end

  def test_attribute_values_are_returned_on_cache_hits
    expect_find(@name_attribute_key, 'foo')
    assert_equal 'foo', AssociatedRecord.fetch_name_by_id(1)
  end

  def test_attribute_values_are_fetched_and_returned_on_cache_misses
    expect_find(@name_attribute_key, nil)
    Record.connection.expects(:select_value).with("SELECT `name` FROM `associated_records` WHERE `id` = 1 LIMIT 1").returns('foo')
    assert_equal 'foo', AssociatedRecord.fetch_name_by_id(1)
  end

  def test_attribute_values_are_stored_in_the_cache_on_cache_misses

    # Cache miss, so
    entry = expect_find(@name_attribute_key, nil)

    # Grab the value of the attribute from the DB
    Record.connection.expects(:select_value).with("SELECT `name` FROM `associated_records` WHERE `id` = 1 LIMIT 1").returns('foo')

    # And write it back to the cache
    entry.expects(:save)
    assert_equal 'foo', AssociatedRecord.fetch_name_by_id(1)
    assert_equal 'foo', entry.value
  end

  def test_cached_attribute_values_are_expired_from_the_cache_when_an_existing_record_is_saved
    IdentityCache::CacheEntry.expects(:delete).with(@name_attribute_key)
    IdentityCache::CacheEntry.expects(:delete).with(@blob_key)
    @record.save!
  end

  def test_cached_attribute_values_are_expired_from_the_cache_when_an_existing_record_with_changed_attributes_is_saved
    IdentityCache::CacheEntry.expects(:delete).with(@name_attribute_key)
    IdentityCache::CacheEntry.expects(:delete).with(@blob_key)
    @record.name = 'bar'
    @record.save!
  end

  def test_cached_attribute_values_are_expired_from_the_cache_when_an_existing_record_is_destroyed
    IdentityCache::CacheEntry.expects(:delete).with(@name_attribute_key)
    IdentityCache::CacheEntry.expects(:delete).with(@blob_key)
    @record.destroy
  end

  def test_cached_attribute_values_are_expired_from_the_cache_when_a_new_record_is_saved
    IdentityCache::CacheEntry.expects(:delete).with("#{NAMESPACE}blob:AssociatedRecord:#{cache_hash("id:integer,name:string,record_id:integer")}:2")
    @parent.associated_records.create(:name => 'bar')
  end

  def test_fetching_by_attribute_delegates_to_block_if_transactions_are_open
    IdentityCache::CacheEntry.expects(:find).with(@name_attribute_key).never

    Record.connection.expects(:select_value).with("SELECT `name` FROM `associated_records` WHERE `id` = 1 LIMIT 1").returns('foo')

    @record.transaction do
      assert_equal 'foo', AssociatedRecord.fetch_name_by_id(1)
    end
  end
end
