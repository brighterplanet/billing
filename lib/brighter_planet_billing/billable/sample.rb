require 'statsample'

module BrighterPlanet
  class Billing
    class Billable
      # flight_sample = BrighterPlanet::Billing.emission_estimate_service.queries.sample :emitter => 'Flight'
      # assert(flight_sample.mean(:emission) > 0)
      # assert(flight_sample.mean(:emission) < 801)
      class Sample
        attr_reader :parent
      
        # attrs
        # * selector
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set "@#{k}", v
          end
        end
        
        # using execution_id as a random attribution
        # thanks http://cookbook.mongodb.org/patterns/random-attribute/
        # ('2'*40) corresponds to 1/8 or 12.50% sample
        THRESHOLD = '2'*40

        def selector_with_random_attribute_threshold
          @selector.symbolize_keys.merge :execution_id => { '$lte' => THRESHOLD }
        end
        
        alias :selector :selector_with_random_attribute_threshold
      
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

        LIMIT = 1_000# 25 #10_000

        def vector(field)
          ary = []
          parent.stream(selector, :limit => LIMIT) do |billable|
            if datapoint = billable.send(field).to_f
              ary.push datapoint
            end
          end
          ary.to_scale
        end
      end
    end
  end
end
