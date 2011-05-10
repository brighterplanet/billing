require 'helper'

class TestEmissionEstimateService < Test::Unit::TestCase
  # if ENV['TRIPCARBON_KEY']
  #   def test_004_sanity_check_top_tripcarbon_results
  #     assert_nothing_raised do
  #       BrighterPlanet.billing.emission_estimate_service.sanity_check(ENV['LIVE_HOST'], ENV['TRIPCARBON_KEY'], :emitter => 'Flight')
  #     end
  #   end
  # end
  
  if ENV['TRIPCARBON_KEY']
    def test_001_sample_query_results
      bill_flight_query
      flight_sample = BrighterPlanet.billing.emission_estimate_service.queries.sample(:selector => {:emitter => 'Flight', :key => ENV['TRIPCARBON_KEY']})
    
      mean, standard_deviation = flight_sample.mean_and_standard_deviation(:emission)
      assert(mean > 100)
      assert(mean < 2000)
    
      assert(standard_deviation > 1)
      assert(standard_deviation < 1000)
    end
    
    def test_002_top_params
      top_params = BrighterPlanet.billing.emission_estimate_service.queries.top(:limit => 1, :field => :params, :selector => {:emitter => 'Flight', :key => ENV['TRIPCARBON_KEY']})
      assert top_params.first.keys.include?('destination_airport')
    end

    def test_003_average_emission_for_top_param
      top_params_for_tripcarbon_flights.each do |p|
        flight_sample = BrighterPlanet.billing.emission_estimate_service.queries.sample(:selector => {:params => p, :key => ENV['TRIPCARBON_KEY']})
        mean, standard_deviation = flight_sample.mean_and_standard_deviation(:emission)
        $stderr.puts mean
        $stderr.puts standard_deviation
        assert (500..1000).include?(mean)
        assert (45..70).include?(standard_deviation)
      end
    end
  end
  
  private
  
  def tripcarbon_flights_selector
    { :emitter => 'Flight', :key => ENV['TRIPCARBON_KEY'] }
  end
  
  def top_params_for_tripcarbon_flights
    @top_params_for_tripcarbon_flights ||= BrighterPlanet.billing.emission_estimate_service.queries.top(:top => 5, :field => :params, :selector => tripcarbon_flights_selector)
  end
end
