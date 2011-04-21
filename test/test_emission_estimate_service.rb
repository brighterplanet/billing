require 'helper'

class TestEmissionEstimateService < Test::Unit::TestCase
  # def test_000_bill_for_a_query
  #   query = bill_flight_query
  #   retrieved_query = BrighterPlanet::Billing.emission_estimate_service.queries.find_one :execution_id => query.execution_id
  #   # the full floating-point precision isn't saved
  #   assert(query.emission - retrieved_query.emission < 0.001)
  #   assert_equal query.certified, retrieved_query.certified
  # end
  
  # if ENV['TRIPCARBON_KEY']
  #   def test_004_sanity_check_top_tripcarbon_results
  #     assert_nothing_raised do
  #       BrighterPlanet::Billing.emission_estimate_service.sanity_check(ENV['LIVE_HOST'], ENV['TRIPCARBON_KEY'], :emitter => 'Flight')
  #     end
  #   end
  # end
  
  if ENV['TRIPCARBON_KEY']
    def test_001_sample_query_results
      bill_flight_query
      flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample(:selector => {:emitter => 'Flight', :key => ENV['TRIPCARBON_KEY']})
    
      mean, standard_deviation = flight_sample.mean_and_standard_deviation(:emission)
      assert(mean > 100)
      assert(mean < 2000)
    
      assert(standard_deviation > 1)
      assert(standard_deviation < 1000)
    end
    
    def test_002_top_params
      top_params = BrighterPlanet::Billing.emission_estimate_service.queries.top(:top => 1, :field => :params, :selector => {:emitter => 'Flight', :key => ENV['TRIPCARBON_KEY']})
      PP.pp top_params.entries, $stderr
      assert_equal 'SFO', top_params.entries.first['destination_airport']['iata_code']
    end

    def test_003_average_emission_for_top_param
      top_param = { "destination_airport"=>{"iata_code"=>"SFO"}, "origin_airport"=>{"iata_code"=>"JAC"}} # just trust me
      flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample(:selector => {:params => top_param, :key => ENV['TRIPCARBON_KEY']})

      mean, standard_deviation = flight_sample.mean_and_standard_deviation(:emission)
      $stderr.puts mean
      $stderr.puts standard_deviation
      assert (750..850).include?(mean)
      assert (45..70).include?(standard_deviation)
    end

    # :live_host => ENV['LIVE_HOST'],
    def test_005_trend_for_top_params
      selector = { :emitter => 'Flight', :key => ENV['TRIPCARBON_KEY'] }
      top_params = BrighterPlanet::Billing.emission_estimate_service.queries.top(:top => 1, :field => :params, :selector => selector)
      PP.pp top_params.entries, $stderr
      emission_trend = BrighterPlanet::Billing.emission_estimate_service.queries.trend(:field => :emission, :selector => selector.merge(top_params.first))
      csv = emission_trend.to_csv
      # params: /flights?origin_airport=jac&destination_airport=sfo
      # field: emission
      #
      # ytd daily
      # date, average, standard_deviation
      # 2011-01-01,231.2,39.2
      assert(/^['"]*\d\d\d\d-\d\d-\d\d['",]+\d+\.\d+['",]+\d+\.\d+['"]*$/m.match(csv))
      #
      # ytd
      # average, standard_deviation
      # 293.2, 291.2
      assert(/^['"]*\d+\.\d+['",]+\d+\.\d+['"]*$/m.match(csv))
      #
      # live
      # host, emission, difference_from_ytd_average
      # cm1-production-red.carbon.brighterplanet.com, 31.2
      # assert(/^['"]*([a-z0-9\.\-]+)['",]+\d+\.\d+['"]*$/m.match(csv))
    end
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
