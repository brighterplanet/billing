require 'statsample'

module BrighterPlanet
  class Billing
    class Billable
      # flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample :emitter => 'Flight'
      # assert(flight_sample.mean(:emission) > 0)
      # assert(flight_sample.mean(:emission) < 801)
      class Sample
        attr_reader :source
        attr_reader :selector
        attr_reader :opts
      
        # using execution_id as a random attribution
        # thanks http://cookbook.mongodb.org/patterns/random-attribute/
        # ('1'*40) corresponds to 1/8 or 12.50% sample
        THRESHOLD = '2'*40
      
        # * prefer newer
        # * drop zeros
      
        def initialize(source, selector, opts = {})
          @source = source
          @selector = (selector || {}).symbolize_keys.merge :execution_id => { '$lte' => THRESHOLD }
          @opts = (opts || {}).symbolize_keys
        end
      
        def mean(field)
          vector(field).mean
        end
      
        def standard_deviation(field)
          vector(field).sd
        end
        
        # faster than doing separately
        def mean_and_standard_deviation(field)
          v = vector(field)
          [ v.mean, v.sd ]
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
          billables.inject([]) do |memo, billable|
            if datapoint = billable.send(field).to_f and datapoint.abs > 0
              memo.push datapoint
            end
            memo
          end.to_scale
        end
      end
    end
  end
end
