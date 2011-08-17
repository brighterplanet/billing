require 'helper'

class TestCm1 < Test::Unit::TestCase
  if ENV['TEST_KEY']
    def test_001_sample_query_results
      flight_sample = BrighterPlanet.billing.cm1.queries.sample(:selector => {:emitter => 'Flight', :key => ENV['TEST_KEY']})
      stats = flight_sample.stats('impact.carbon', :mean, :sd)
      assert (100..2000).include?(stats[:mean])
      assert (0..2000).include?(stats[:sd])
    end
    
    def test_002_top_input
      top_input = BrighterPlanet.billing.cm1.queries.top :field => 'input', :selector => {:emitter => 'Flight', :key => ENV['TEST_KEY']}, :limit => 1
      assert top_input.first.keys.include?('destination_airport')
    end
    
    def test_003_average_impact_for_top_input
      top_input_for_example_flights.each do |p|
        flight_sample = BrighterPlanet.billing.cm1.queries.sample(:selector => {:input => p, :key => ENV['TEST_KEY']})
        stats = flight_sample.stats('impact.carbon', :mean, :sd)
        assert (100..2000).include?(stats[:mean])
        assert (0..100).include?(stats[:sd])
      end
    end
    
    def test_004_usage
      usage = BrighterPlanet.billing.cm1.queries.usage(:start_at => Time.parse('2011-04-01'), :end_at => Time.parse('2011-05-01'), :period => 5.days, :selector => { :key => ENV['TEST_KEY']})
      assert(usage.select { |date, usage| usage > 100 }.length > 3)
    end
  end
  
  private
  
  def example_flights_selector
    { :emitter => 'Flight', :key => ENV['TEST_KEY'] }
  end
  
  def top_input_for_example_flights
    @top_input_for_example_flights ||= BrighterPlanet.billing.cm1.queries.top(:top => 5, :field => :input, :selector => example_flights_selector)
  end
end
