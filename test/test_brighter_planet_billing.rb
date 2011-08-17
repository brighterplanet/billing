require 'helper'

TEST_TIME_ATTRS = [ :started_at, :stopped_at, :timeframe_from, :timeframe_to ]

class TestBrighterPlanetBilling < Test::Unit::TestCase  
  def test_001_count
    assert(::BrighterPlanet.billing.cm1.queries.count > 1_000)
  end
  
  def test_002_all_keys
    assert(BrighterPlanet.billing.keys.all.length > 0)
  end
  
  def test_011_immediate_store_to_mongo
    ::BrighterPlanet.billing.config.disable_caching = true
    input = { 'make' => 'Nissan', 'key' => 'test_store_to_mongo', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    impact = { 'carbon' => 49213 }
    execution_id = nil
    ::BrighterPlanet.billing.cm1.bill do |query|
      query.certified = true
      query.key = input['key']
      query.timeframe = Timeframe.this_year
      query.input = input
      query.url = input['url']
      query.emitter = 'Automobile'
      if input['key'] and input['url']
        query.remote_ip = input['remote_ip']
        query.referer = input['referer']
      end
      query.impact = impact
      execution_id = query.execution_id # so we can look at it
    end
    sleep 1
    stored_query = ::BrighterPlanet.billing.cm1.queries.find_one(:execution_id => execution_id)
    TEST_TIME_ATTRS.each do |time_attr|
      assert_equal ::Time, stored_query.send(time_attr).class
    end
    assert_equal 'Cm1', stored_query.service.class.to_s.demodulize
    assert_equal true, stored_query.certified
    assert_equal 'Automobile', stored_query.emitter
    assert_equal impact, stored_query.impact
  end

  def test_012_delayed_store_to_mongo
    input = { 'make' => 'Nissan', 'key' => 'hiseamus', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    impact = { 'carbon' => 29102 }
    execution_id = nil
    assert_false ::BrighterPlanet.billing.config.disable_caching?
    ::BrighterPlanet.billing.cm1.bill do |query|
      query.certified = false
      query.timeframe = Timeframe.this_year
      query.key = input['key']
      query.input = input
      query.url = input['url']
      query.emitter = 'Automobile'
      if input['key'] and input['url']
        query.remote_ip = input['remote_ip']
        query.referer = input['referer']
      end
      query.impact = impact
      execution_id = query.execution_id
    end
    assert_nil ::BrighterPlanet.billing.cm1.queries.find_one(:execution_id => execution_id)
    ::BrighterPlanet::Billing::CacheEntry.synchronize
    sleep 1
    stored_query = ::BrighterPlanet.billing.cm1.queries.find_one(:execution_id => execution_id)
    TEST_TIME_ATTRS.each do |time_attr|
      assert_equal ::Time, stored_query.send(time_attr).class
    end
    assert_equal 'Cm1', stored_query.service.class.to_s.demodulize
    assert_equal false, stored_query.certified
    assert_equal 'Automobile', stored_query.emitter
    assert_equal impact, stored_query.impact
  end
  
  def test_016_can_immediately_get_execution_id
    ::BrighterPlanet.billing.cm1.bill do |query|
      assert_equal ::String, query.execution_id.class
    end
  end
  
  def test_017_really_runs_block
    confirmation = catch :i_ran do
      ::BrighterPlanet.billing.cm1.bill do |query|
        throw :i_ran, :yes_i_did
      end
    end
    assert_equal :yes_i_did, confirmation
  end
  
  def test_018_synchronization
    assert BrighterPlanet::Billing::Synchronization.respond_to? :perform
  end
end
