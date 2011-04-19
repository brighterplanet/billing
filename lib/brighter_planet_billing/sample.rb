require 'statsample'

module BrighterPlanet
  class Billing
    # flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample :emitter => 'Flight'
    # assert(flight_sample.mean(:emission) > 0)
    # assert(flight_sample.mean(:emission) < 801)
    class Sample
      attr_reader :source
      attr_reader :selector
      attr_reader :opts
      
      # using execution_id as a random attribution
      # thanks http://cookbook.mongodb.org/patterns/random-attribute/
      # ('1'*40) corresponds to 1/16 or 6.25% sample
      # this can be further limited by passing :limit => 5000 in the opts
      THRESHOLD = '1'*40
      LIMIT = 10_000
      
      # * prefer newer
      # * drop zeros
      
      def initialize(source, selector, opts = {})
        @source = source
        @selector = (selector || {}).symbolize_keys.merge :execution_id => { '$lte' => THRESHOLD }
        @opts = (opts || {}).symbolize_keys.reverse_merge :limit => LIMIT
      end
      
      def mean(field)
        vector(field).mean
      end
      
      def standard_deviation(field)
        vector(field).sd
      end
      
      def billables
        return @billables if @billables.is_a?(::Array)
        @billables = []
        source.stream(selector, opts) do |billable|
          @billables.push billable
        end
        @billables
      end
      
      def vector(field)
        billables.map { |billable| billable.send(field).to_f }.to_scale
      end
    end
  end
end
