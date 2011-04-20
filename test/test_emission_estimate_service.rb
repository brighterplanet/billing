require 'helper'

class TestEmissionEstimateService < Test::Unit::TestCase
  # def test_000_bill_for_a_query
  #   query = bill_flight_query
  #   retrieved_query = BrighterPlanet::Billing.emission_estimate_service.queries.find_one :execution_id => query.execution_id
  #   # the full floating-point precision isn't saved
  #   assert(query.emission - retrieved_query.emission < 0.001)
  #   assert_equal query.certified, retrieved_query.certified
  # end
  
  # def test_001_sample_query_results
  #   bill_flight_query
  #   flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample({:emitter => 'Flight', :emission => { '$exists' => true }}, :limit => 25)
  #   
  #   mean_emission = flight_sample.mean(:emission)
  #   $stderr.puts mean_emission
  #   assert(mean_emission > 100)
  #   assert(mean_emission < 2000)
  #   
  #   standard_deviation_emission = flight_sample.standard_deviation(:emission)
  #   $stderr.puts standard_deviation_emission
  #   assert(standard_deviation_emission > 1)
  #   assert(standard_deviation_emission < 100)
  # end
  
  def test_002_top_params
    top_params = BrighterPlanet::Billing.emission_estimate_service.queries.top_values(10, :params, :emitter => 'Flight')
    assert_equal 'SFO', top_params[0]['destination_airport']['iata_code']
  end
  
  def test_003_average_emission_for_top_param
    top_param = { "destination_airport"=>{"iata_code"=>"SFO"}, "origin_airport"=>{"iata_code"=>"JAC"}} # just trust me
    flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample(:params => top_param)

    mean, standard_deviation = flight_sample.mean_and_standard_deviation(:emission)
    # $stderr.puts mean
    assert (750..850).include?(mean)
    # $stderr.puts standard_deviation
    assert (45..70).include?(standard_deviation)
  end

  if ENV['TRIPCARBON_KEY']
    def test_004_sanity_check_top_tripcarbon_results
      host = 'cm1-production-red.carbon.brighterplanet.com'
      assert_nothing_raised do
        BrighterPlanet::Billing.emission_estimate_service.sanity_check(host, ENV['TRIPCARBON_KEY'], :emitter => 'Flight')
      end
    end
  else
    $stderr.puts "Skipping tripcarbon test"
  end
  
  private
  
  def bill_flight_query
    query = BrighterPlanet::Billing.emission_estimate_service.bill do |query|
      query.key = 'TestEmissionEstimateService#bill_flight_query'
      query.emitter = 'Flight'
      query.certified = false
      query.emission = rand(800) + rand
      query.color = [ :red, :blue ].sort_by { rand }[0]
    end
    BrighterPlanet::Billing.synchronize
    sleep 5
    query
  end
end
