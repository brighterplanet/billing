module BrighterPlanet
  class Billing
    class Billable
      class Usage
        attr_reader :parent
        attr_reader :selector
      
        include ::Enumerable
        
        include TimeAttrs
      
        # attrs
        # * selector
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set "@#{k}", v
          end
        end

        def each
          moment = start_at
          while moment < end_at
            count = parent.count(selector.merge(:started_at => { '$gte' => moment, '$lt' => (moment + precision) }))
            yield [moment.dup, count]
            moment += precision
          end
        end
        
        include ToCSV
        
        def write_csv(f, options = {})
          f.puts [ 'date', 'count' ].to_csv
          each do |date, count|
            f.puts [ date, count ].to_csv
          end
        end
      end
    end
  end
end
