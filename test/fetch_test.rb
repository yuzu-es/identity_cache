require "test_helper"

class FetchTest < IdentityCache::TestCase
  NAMESPACE = IdentityCache::CacheKeyGeneration::DEFAULT_NAMESPACE

  def setup
    super
    @cache = IdentityCache.cache_backend

    Record.cache_index :title, :unique => true
    Record.cache_index :id, :title, :unique => true

    @record = Record.new
    @record.id = 1
    @record.title = 'bob'
    @cached_value = {:class => @record.class}
    @record.encode_with(@cached_value)
    @blob_key = "#{NAMESPACE}blob:Record:#{cache_hash("created_at:datetime,id:integer,record_id:integer,title:string,updated_at:datetime")}:1"
    @index_key = "#{NAMESPACE}index:Record:title:#{cache_hash('bob')}"
  end

  def test_fetch_cache_hit
    @cache.expects(:get).with(@blob_key).returns([@cached_value, 0])

    assert_equal @record, Record.fetch(1)
  end

  def test_fetch_hit_cache_namespace
    Record.send(:include, SwitchNamespace)
    Record.namespace = 'test_namespace'

    new_blob_key = "test_namespace:#{@blob_key}"
    @cache.expects(:get).with(new_blob_key).returns([@cached_value, 0])

    assert_equal @record, Record.fetch(1)
  end

  def test_exists_with_identity_cache_when_cache_hit
    @cache.expects(:get).with(@blob_key).returns([@cached_value, 0])

    assert Record.exists_with_identity_cache?(1)
  end

  def test_exists_with_identity_cache_when_cache_miss_and_in_db
    @cache.expects(:get).with(@blob_key).returns([nil, nil])
    Record.expects(:find_by_id).with(1, :include => []).returns(@record)

    assert Record.exists_with_identity_cache?(1)
  end

  def test_exists_with_identity_cache_when_cache_miss_and_not_in_db
    @cache.expects(:get).with(@blob_key).returns([nil, nil])
    Record.expects(:find_by_id).with(1, :include => []).returns(nil)

    assert !Record.exists_with_identity_cache?(1)
  end

  def test_fetch_miss
    Record.expects(:find_by_id).with(1, :include => []).returns(@record)

    @cache.expects(:get).with(@blob_key).returns([nil, nil])
    @cache.expects(:add).with(@blob_key, @cached_value)

    assert_equal @record, Record.fetch(1)
  end

  def test_fetch_by_id_not_found_should_return_nil
    nonexistent_record_id = 10
    @cache.expects(:add).with(@blob_key + '0', IdentityCache::CACHED_NIL)

    assert_equal nil, Record.fetch_by_id(nonexistent_record_id)
  end

  def test_fetch_not_found_should_raise
    nonexistent_record_id = 10
    @cache.expects(:add).with(@blob_key + '0', IdentityCache::CACHED_NIL)

    assert_raises(ActiveRecord::RecordNotFound) { Record.fetch(nonexistent_record_id) }
  end

  def test_cached_nil_expiry_on_record_creation
    key = @record.primary_cache_index_key

    assert_equal nil, Record.fetch_by_id(@record.id)
    assert_equal IdentityCache::CACHED_NIL, @cache.get(key)[0]

    @record.save!
    assert_nil @cache.get(key)
  end

  def test_fetch_by_title_hit
    # Read record with title bob
    @cache.expects(:get).with(@index_key).returns([nil, nil])

    # - not found, use sql, SELECT id FROM records WHERE title = '...' LIMIT 1"
    Record.connection.expects(:select_value).returns(1)

    # cache sql result
    @cache.expects(:add).with(@index_key, 1)

    # got id, do memcache lookup on that, hit -> done
    @cache.expects(:get).with(@blob_key).returns([@cached_value, 0])

    assert_equal @record, Record.fetch_by_title('bob')
  end

  def test_fetch_by_title_cache_namespace
    Record.send(:include, SwitchNamespace)
    @cache.expects(:get).with("ns:#{@index_key}").returns([1, 0])
    @cache.expects(:get).with("ns:#{@blob_key}").returns([@cached_value, 0])

    assert_equal @record, Record.fetch_by_title('bob')
  end

  def test_fetch_by_title_stores_idcnil
    Record.connection.expects(:select_value).once.returns(nil)
    @cache.expects(:add).with(@index_key, IdentityCache::CACHED_NIL)
    @cache.expects(:get).with(@index_key).times(3).returns([nil, nil], [IdentityCache::CACHED_NIL, 0], [IdentityCache::CACHED_NIL, 0])

    assert_equal nil, Record.fetch_by_title('bob') # select_value => nil

    assert_equal nil, Record.fetch_by_title('bob') # returns cached nil
    assert_equal nil, Record.fetch_by_title('bob') # returns cached nil
  end

  def test_fetch_by_bang_method
    Record.connection.expects(:select_value).returns(nil)
    assert_raises ActiveRecord::RecordNotFound do
      Record.fetch_by_title!('bob')
    end
  end
end
