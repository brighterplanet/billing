require 'helper'

class TestBrighterPlanetBilling < Test::Unit::TestCase
  def setup
    ::BrighterPlanet::Billing.setup
    ::BrighterPlanet::Billing.config.slow_is_ok = false
    ::BrighterPlanet::Billing.config.disable_hoptoad = false
  end
  
  def test_report_per_key
    report = ::BrighterPlanet::Billing.emission_estimate_service.reports.find_by_key '17a0c34541c953b5430adf8e2a1f50fb'
    assert(report.queries.length > 0)
  end
  
  def test_immediate_store_to_sdb
    ::BrighterPlanet::Billing.config.slow_is_ok = true
    params = { 'make' => 'Nissan', 'key' => 'test_store_to_sdb', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    answer = { 'emission' => '49291' }
    execution_id = nil
    ::BrighterPlanet::Billing.emission_estimate_service.queries.start do |query|
      query.key = params['key']
      query.input_params = params
      query.url = params['url']
      query.emitter_common_name = 'automobile'
      if params['key'] and params['url']
        query.remote_ip = params['remote_ip']
        query.referer = params['referer']
      end
      query.execute do
        # rubber stamp
      end
      query.output_params = answer
      execution_id = query.execution_id
    end
    sleep 1
    stored_query = ::BrighterPlanet::Billing.emission_estimate_service.queries.find_by_execution_id execution_id
    assert_equal 'emission_estimate_service', stored_query.service
    assert_equal answer['emission'], stored_query.output_params['emission']
  end
  
  def test_delayed_store_to_sdb
    params = { 'make' => 'Nissan', 'key' => 'test_store_to_sdb', 'url' => 'http://carbon.brighterplanet.com/automobiles.json?make=Nissan' }
    answer = { 'emission' => '49291' }
    execution_id = nil
    assert !::BrighterPlanet::Billing.config.slow_is_ok?
    ::BrighterPlanet::Billing.emission_estimate_service.queries.start do |query|
      query.key = params['key']
      query.input_params = params
      query.url = params['url']
      query.emitter_common_name = 'automobile'
      if params['key'] and params['url']
        query.remote_ip = params['remote_ip']
        query.referer = params['referer']
      end
      query.execute do
        # rubber stamp
      end
      query.output_params = answer
      execution_id = query.execution_id
    end
    sleep 1
    assert_nil ::BrighterPlanet::Billing.emission_estimate_service.queries.find_by_execution_id(execution_id)
    ::BrighterPlanet::Billing.synchronize
    sleep 1
    stored_query = ::BrighterPlanet::Billing.emission_estimate_service.queries.find_by_execution_id execution_id
    assert_equal 'emission_estimate_service', stored_query.service
    assert_equal answer['emission'], stored_query.output_params['emission']
  end
  
  def test_catches_errors_with_hoptoad
    assert_raises(::BrighterPlanet::Billing::ReportedExceptionToHoptoad) do
      ::BrighterPlanet::Billing.emission_estimate_service.queries.start do |query|
        query.execute { raise StandardError }
      end
    end
  end
  
  def test_catches_errors_without_hoptoad
    ::BrighterPlanet::Billing.config.disable_hoptoad = true
    assert_raises(StandardError) do
      ::BrighterPlanet::Billing.emission_estimate_service.queries.start do |query|
        query.execute { raise StandardError }
      end
    end
  end
end
