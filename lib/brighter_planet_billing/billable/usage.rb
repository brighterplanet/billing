module BrighterPlanet
  class Billing
    class Billable
      class Usage
        attr_reader :parent
        attr_reader :selector
      
        include ::Enumerable
      
        # attrs
        # * first_day
        # * last_day
        # * selector
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set "@#{k}", v
          end
        end

        def first_day
          (@first_day ||= (::Date.today - 1.month)).to_date
        end
        
        def last_day
          (@last_day ||= ::Date.today).to_date
        end

        def each
          (first_day..last_day).each do |date|
            count = parent.count(selector.merge(:started_at => { '$gte' => date.to_time, '$lt' => date.tomorrow.to_time }))
            yield [date, count]
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
