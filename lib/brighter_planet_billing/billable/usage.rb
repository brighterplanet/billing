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
          each_moment do |moment, moment_selector|
            count = parent.count selector.merge(:started_at => moment_selector)
            yield [moment, count]
          end
        end
        
        include ToCSV
        
        def write_csv(f, options = {})
          f.puts [ 'time', 'count' ].to_csv
          each do |time, count|
            f.puts [ time, count ].to_csv
          end
        end
      end
    end
  end
end
