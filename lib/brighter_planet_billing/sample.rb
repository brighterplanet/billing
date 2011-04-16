require 'statdatapoints'

module BrighterPlanet
  class Billing
    # flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample :emitter => 'Flight'
    # assert(flight_sample.mean(:emission) > 0)
    # assert(flight_sample.mean(:emission) < 801)
    class Sample
      attr_reader :billables
      attr_reader :selector
      attr_reader :opts
      
      # using execution_id as a random attribution
      # thanks http://cookbook.mongodb.org/patterns/random-attribute/
      # ('1'*40) corresponds to 1/16 or 6.25% sample
      # this can be further limited by passing :limit => 5000 in the opts
      SAMPLE_THRESHOLD = '1'*40
      
      def initialize(billables, selector, opts = {})
        @billables = billables
        @selector = selector
        @opts = opts
      end
      
      def mean(field)
        vector(field).mean
      end
      
      def variance(field)
        vector(field).variance
      end
      
      private
      
      def datapoints
        @datapoints ||= billables.stream(selector.merge(:execution_id => { '$lte' => SAMPLE_THRESHOLD }), opts) do |billable|
          datapoints.push billable
        end
      end
      
      def vector(field)
        datapoints.map { |billable| billable.send(field) }.to_scale
      end
    end
  end
end
