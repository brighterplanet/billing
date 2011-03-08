require 'helper'

class TestBrighterPlanetBilling < Test::Unit::TestCase
  def setup
    ::BrighterPlanet::Billing.setup
    ::BrighterPlanet::Billing.config.slow_is_ok = false
    ::BrighterPlanet::Billing.config.disable_hoptoad = false
    ::BrighterPlanet::Billing.config.allowed_exceptions.clear
  end

  # sabshere 3/8/11 this is super slow
  # def test_keys
  #   keys = ::BrighterPlanet::Billing.emission_estimate_service.keys.all
  #   assert keys.map(&:key).include?('17a0c34541c953b5430adf8e2a1f50fb')
  # end
  
  def test_count
    assert(::BrighterPlanet::Billing.emission_estimate_service.queries.count > 1_000)
  end
  
  def test_count_by_key
    key_query_count = ::BrighterPlanet::Billing.emission_estimate_service.queries.count_by_key('17a0c34541c953b5430adf8e2a1f50fb')
    assert(key_query_count > 1_000)
  end
  
  def test_count_by_blank_key
    key_query_count = ::BrighterPlanet::Billing.emission_estimate_service.queries.count_by_key(nil)
    assert(key_query_count > 1_000)
  end
  
  # deprecated
  def test_count_by_emitter_common_name
    flight_query_count = ::BrighterPlanet::Billing.emission_estimate_service.queries.count_by_emitter_common_name('flight')
    assert(flight_query_count > 1_000)
  end
  
  def test_count_by_emitter
    flight_query_count = ::BrighterPlanet::Billing.emission_estimate_service.queries.count_by_emitter('Flight')
    assert(flight_query_count > 1_000)
  end
  
  def test_count_by_month
    december = ::BrighterPlanet::Billing.emission_estimate_service.queries.count_by_month(2010, 12)
    all_time = ::BrighterPlanet::Billing.emission_estimate_service.queries.count
    assert(december > 1_000)
    assert(all_time > december)
  end
  
  def test_zzz_key_yields_queries
    key = ::BrighterPlanet::Billing.emission_estimate_service.keys.find_by_key '17a0c34541c953b5430adf8e2a1f50fb'
    catch :found_it do
      assert_nothing_raised do
        key.each_query do |query|
          throw :found_it
          raise "didn't find it!"
        end
      end
    end
  end
  
  def test_zzz_key_yields_queries_per_month
    key = ::BrighterPlanet::Billing.emission_estimate_service.keys.find_by_key '17a0c34541c953b5430adf8e2a1f50fb'
    catch :found_it do
      assert_nothing_raised do
        key.each_query(2010, 11) do |query|
          throw :found_it
          raise "didn't find it!"
        end
      end
    end
  end
  
  def test_zzz_key_yields_queries_per_month_false_positives
    key = ::BrighterPlanet::Billing.emission_estimate_service.keys.find_by_key '17a0c34541c953b5430adf8e2a1f50fb'
    assert_nothing_raised do
      key.each_query(2009, 11) do |query|
        raise "uhh ohh, found something!"
      end
    end
  end
  
  def test_zzz_query_to_csv
    ticks = 2
    key = ::BrighterPlanet::Billing.emission_estimate_service.keys.find_by_key '17a0c34541c953b5430adf8e2a1f50fb'
    key.each_query do |query|
      assert(query.to_csv.length > 0)
      ticks -= 1
      break if ticks < 0
    end
  end
  
  def test_immediate_store_to_mongo
    ::BrighterPlanet::Billing.config.slow_is_ok = true
    params = { 'make' => 'Nissan', 'key' => 'test_store_to_mongo', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    answer = { 'emission' => '49291' }
    execution_id = nil
    ::BrighterPlanet::Billing.emission_estimate_service.queries.execute do |query|
      query.certified = true
      query.key = params['key']
      query.input_params = params
      query.url = params['url']
      # deprecated
      query.emitter_common_name = 'automobile'
      query.emitter = 'Automobile'
      if params['key'] and params['url']
        query.remote_ip = params['remote_ip']
        query.referer = params['referer']
      end
      # ... do nothing ...
      query.output_params = answer
      execution_id = query.execution_id
    end
    sleep 1
    stored_query = ::BrighterPlanet::Billing.emission_estimate_service.queries.find_by_execution_id execution_id
    assert_equal 'EmissionEstimateService', stored_query.service
    assert_equal true, stored_query.certified
    assert_equal 'Automobile', stored_query.emitter
    assert_equal answer['emission'], stored_query.output_params['emission']
  end

  def test_delayed_store_to_mongo
    params = { 'make' => 'Nissan', 'key' => 'hiseamus', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    answer = { 'emission' => '29102' }
    execution_id = nil
    assert_false ::BrighterPlanet::Billing.config.slow_is_ok?
    ::BrighterPlanet::Billing.emission_estimate_service.queries.execute do |query|
      query.certified = false
      query.key = params['key']
      query.input_params = params
      query.url = params['url']
      # deprecated
      query.emitter_common_name = 'automobile'
      query.emitter = 'Automobile'
      if params['key'] and params['url']
        query.remote_ip = params['remote_ip']
        query.referer = params['referer']
      end
      # ..... do nothing ....
      query.output_params = answer
      execution_id = query.execution_id
    end
    assert_nil ::BrighterPlanet::Billing.emission_estimate_service.queries.find_by_execution_id(execution_id)
    ::BrighterPlanet::Billing.synchronize
    sleep 1
    stored_query = ::BrighterPlanet::Billing.emission_estimate_service.queries.find_by_execution_id execution_id
    assert_equal 'EmissionEstimateService', stored_query.service
    assert_equal false, stored_query.certified
    assert_equal 'Automobile', stored_query.emitter
    assert_equal answer['emission'], stored_query.output_params['emission']
  end
  
  def test_catches_errors_with_hoptoad
    assert_raises(::BrighterPlanet::Billing::ReportedExceptionToHoptoad) do
      ::BrighterPlanet::Billing.emission_estimate_service.queries.execute do |query|
        raise StandardError
      end
    end
  end
  
  def test_catches_errors_without_hoptoad
    ::BrighterPlanet::Billing.config.disable_hoptoad = true
    assert_raises(StandardError) do
      ::BrighterPlanet::Billing.emission_estimate_service.queries.execute do |query|
        raise StandardError
      end
    end
  end
  
  def test_allows_certain_errors_through
    require 'leap'
    ::BrighterPlanet::Billing.config.allowed_exceptions.push ::Leap::NoSolutionError
    assert_raises(::Leap::NoSolutionError) do
      ::BrighterPlanet::Billing.emission_estimate_service.queries.execute do |query|
        raise ::Leap::NoSolutionError
      end
    end
  end
  
  def test_can_immediately_get_execution_id
    ::BrighterPlanet::Billing.emission_estimate_service.queries.execute do |query|
      assert_equal ::String, query.execution_id.class
    end
  end
  
  def test_really_runs_block
    $test_really_runs_block_ran = false
    ::BrighterPlanet::Billing.emission_estimate_service.queries.execute do |query|
      $test_really_runs_block_ran = true
    end
    assert $test_really_runs_block_ran
  end
end
