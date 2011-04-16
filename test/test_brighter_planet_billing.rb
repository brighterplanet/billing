require 'helper'

class TestBrighterPlanetBilling < Test::Unit::TestCase
  # sabshere 3/8/11 this is super slow
  # def test_000_keys
  #   keys = ::BrighterPlanet::Billing.keys.all
  #   assert keys.map(&:key).include?('17a0c34541c953b5430adf8e2a1f50fb')
  # end
  
  def test_001_count
    assert(::BrighterPlanet::Billing.emission_estimate_service.queries.count > 1_000)
  end
  
  def test_002_count_by_key
    key_query_count = ::BrighterPlanet::Billing.emission_estimate_service.queries.count(:key => '17a0c34541c953b5430adf8e2a1f50fb')
    assert(key_query_count > 1_000)
  end
  
  def test_003_count_by_blank_key
    key_query_count = ::BrighterPlanet::Billing.emission_estimate_service.queries.count(:key => nil)
    assert(key_query_count > 1_000)
  end
    
  def test_005_count_by_emitter
    flunk
    flight_query_count = ::BrighterPlanet::Billing.emission_estimate_service.queries.count(:emitter => 'Flight')
    assert(flight_query_count > 1_000)
  end
  
  def test_006_count_by_month
    december = ::BrighterPlanet::Billing.emission_estimate_service.queries.count(:year => 2010, :month => 12)
    all_time = ::BrighterPlanet::Billing.emission_estimate_service.queries.count
    assert(december > 1_000)
    assert(all_time > december)
  end
    
  def test_011_immediate_store_to_mongo
    ::BrighterPlanet::Billing.config.disable_caching = true
    params = { 'make' => 'Nissan', 'key' => 'test_store_to_mongo', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    answer = { 'emission' => '49291' }
    execution_id = nil
    ::BrighterPlanet::Billing.emission_estimate_service.bill do |query|
      query.certified = true
      query.key = params['key']
      query.input_params = params
      query.url = params['url']
      query.emitter = 'Automobile'
      if params['key'] and params['url']
        query.remote_ip = params['remote_ip']
        query.referer = params['referer']
      end
      query.output_params = answer
      execution_id = query.execution_id # so we can look at it
    end
    sleep 1
    stored_query = ::BrighterPlanet::Billing.emission_estimate_service.queries.find_one(:execution_id => execution_id)
    assert_equal 'EmissionEstimateService', stored_query.service.name
    assert_equal true, stored_query.certified
    assert_equal 'Automobile', stored_query.emitter
    assert_equal answer['emission'], stored_query.output_params['emission']
  end

  def test_012_delayed_store_to_mongo
    params = { 'make' => 'Nissan', 'key' => 'hiseamus', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    answer = { 'emission' => '29102' }
    execution_id = nil
    assert_false ::BrighterPlanet::Billing.config.disable_caching?
    ::BrighterPlanet::Billing.emission_estimate_service.bill do |query|
      query.certified = false
      query.key = params['key']
      query.input_params = params
      query.url = params['url']
      query.emitter = 'Automobile'
      if params['key'] and params['url']
        query.remote_ip = params['remote_ip']
        query.referer = params['referer']
      end
      query.output_params = answer
      execution_id = query.execution_id
    end
    assert_nil ::BrighterPlanet::Billing.emission_estimate_service.queries.find_one(:execution_id => execution_id)
    ::BrighterPlanet::Billing.synchronize
    sleep 1
    stored_query = ::BrighterPlanet::Billing.emission_estimate_service.queries.find_one(:execution_id => execution_id)
    assert_equal 'EmissionEstimateService', stored_query.service.name
    assert_equal false, stored_query.certified
    assert_equal 'Automobile', stored_query.emitter
    assert_equal answer['emission'], stored_query.output_params['emission']
  end
  
  def test_013_catches_errors_with_hoptoad
    assert_raises(::BrighterPlanet::Billing::ReportedExceptionToHoptoad) do
      ::BrighterPlanet::Billing.emission_estimate_service.bill do |query|
        raise StandardError
      end
    end
  end
  
  def test_014_catches_errors_without_hoptoad
    ::BrighterPlanet::Billing.config.disable_hoptoad = true
    assert_raises(StandardError) do
      ::BrighterPlanet::Billing.emission_estimate_service.bill do |query|
        raise StandardError
      end
    end
  end
  
  def test_015_allows_certain_errors_through
    require 'leap'
    ::BrighterPlanet::Billing.config.allowed_exceptions.push ::Leap::NoSolutionError
    assert_raises(::Leap::NoSolutionError) do
      ::BrighterPlanet::Billing.emission_estimate_service.bill do |query|
        raise ::Leap::NoSolutionError
      end
    end
  end
  
  def test_016_can_immediately_get_execution_id
    ::BrighterPlanet::Billing.emission_estimate_service.bill do |query|
      assert_equal ::String, query.execution_id.class
    end
  end
  
  def test_017_really_runs_block
    confirmation = catch :i_ran do
      ::BrighterPlanet::Billing.emission_estimate_service.bill do |query|
        throw :i_ran, :yes_i_did
      end
    end
    assert_equal :yes_i_did, confirmation
  end

  def test_999_key_yields_queries
    catch :found_it do
      assert_nothing_raised do
        ::BrighterPlanet::Billing.emission_estimate_service.queries.stream(:key => '17a0c34541c953b5430adf8e2a1f50fb') do |query|
          throw :found_it
          raise "didn't find it!"
        end
      end
    end
  end
  
  def test_998_key_yields_queries_per_month
    catch :found_it do
      assert_nothing_raised do
        ::BrighterPlanet::Billing.emission_estimate_service.queries.stream(:year => 2010, :month => 11, :key => '17a0c34541c953b5430adf8e2a1f50fb') do |query|
          throw :found_it
          raise "didn't find it!"
        end
      end
    end
  end
  
  def test_997_key_yields_queries_per_month_false_positives
    assert_nothing_raised do
      ::BrighterPlanet::Billing.emission_estimate_service.queries.stream(:year => 2009, :month => 11, :key => '17a0c34541c953b5430adf8e2a1f50fb') do |query|
        raise "uhh ohh, found something!"
      end
    end
  end
end
