require 'helper'

class TestEmissionEstimateService < Test::Unit::TestCase
  if ENV['TEST_KEY']
    def test_001_sample_query_results
      flight_sample = BrighterPlanet.billing.emission_estimate_service.queries.sample(:selector => {:emitter => 'Flight', :key => ENV['TEST_KEY']})
    
      mean, standard_deviation = flight_sample.mean_and_standard_deviation(:emission)
      assert(mean > 100)
      assert(mean < 2000)
    
      assert(standard_deviation > 1)
      assert(standard_deviation < 1000)
    end
    
    def test_002_top_params
      top_params = BrighterPlanet.billing.emission_estimate_service.queries.top(:limit => 1, :field => :params, :selector => {:emitter => 'Flight', :key => ENV['TEST_KEY']})
      assert top_params.first.keys.include?('destination_airport')
    end
    
    def test_003_average_emission_for_top_param
      top_params_for_example_flights.each do |p|
        flight_sample = BrighterPlanet.billing.emission_estimate_service.queries.sample(:selector => {:params => p, :key => ENV['TEST_KEY']})
        mean, standard_deviation = flight_sample.mean_and_standard_deviation(:emission)
        $stderr.puts mean
        $stderr.puts standard_deviation
        assert (500..1000).include?(mean)
        assert (45..70).include?(standard_deviation)
      end
    end
    
    def test_004_usage
      usage = BrighterPlanet.billing.emission_estimate_service.queries.usage(:first_day => Time.parse('2011-04-01'), :last_day => Time.parse('2011-05-01'), :selector => { :key => ENV['TEST_KEY']})
      assert(usage.select { |date, usage| usage > 100 }.length > 3)
    end
  end
  
  private
  
  def example_flights_selector
    { :emitter => 'Flight', :key => ENV['TEST_KEY'] }
  end
  
  def top_params_for_example_flights
    @top_params_for_example_flights ||= BrighterPlanet.billing.emission_estimate_service.queries.top(:top => 5, :field => :params, :selector => example_flights_selector)
  end
end
