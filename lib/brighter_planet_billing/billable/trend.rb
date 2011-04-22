module BrighterPlanet
  class Billing
    class Billable
      class Trend
        attr_reader :parent
        attr_reader :field
        attr_reader :selector
      
        # attrs
        # * field
        # * selector
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set "@#{k}", v
          end
        end
      
        def year
          ::Time.now.year
        end
            
        def each
          (Date.today.at_beginning_of_year..Date.today).each do |date|
            mean, standard_deviation = parent.sample(:selector => selector.merge(:started_at => { '$gte' => date.to_time, '$lt' => date.tomorrow.to_time })).mean_and_standard_deviation(field)
            yield [ date, mean, standard_deviation ]
          end
        end
        
        include ToCSV
        
        def write_csv(f, options = {})
          f.puts [ 'date', 'mean', 'standard_deviation' ].to_csv
          each do |date, mean, standard_deviation|
            f.puts [ date, mean, standard_deviation ].to_csv
          end
        end
      end
    end
  end
end
