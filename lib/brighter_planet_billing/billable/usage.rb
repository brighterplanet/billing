module BrighterPlanet
  class Billing
    class Billable
      class Usage
        attr_reader :parent
      
        include ::Enumerable
        
        include TimeAttrs
      
        # attrs
        # * selector
        # * include_failed (default false)
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end
        
        def include_failed?
          !!@include_failed
        end
        
        def selector_with_failure_exclusion
          include_failed? ? @selector : @selector.merge(:succeeded => true)
        end
        
        alias :selector :selector_with_failure_exclusion

        def each
          each_moment do |moment, moment_selector|
            count = parent.count selector.merge(:started_at => moment_selector)
            yield [moment, count]
          end
        end
        
        def columns
          [ 'period_starting', 'count' ]
        end
        
        include ToCSV
        
        def write_csv(f)
          f.puts columns.to_csv
          each do |time, count|
            f.puts [ period_starting(time), count ].to_csv
          end
        end
      end
    end
  end
end
