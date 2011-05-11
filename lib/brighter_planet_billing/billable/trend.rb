module BrighterPlanet
  class Billing
    class Billable
      class Trend
        attr_reader :parent
        attr_reader :field
        attr_reader :selector

        include TimeAttrs

        # attrs
        # * field
        # * selector
        # # start_at / end_at / hours / days
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set "@#{k}", v
          end
        end

        def each
          each_moment do |moment, moment_selector|
            mean, standard_deviation = parent.sample(:selector => selector.merge(:started_at => moment_selector)).mean_and_standard_deviation(field)
            yield [ moment, mean, standard_deviation ]
          end
        end

        include ToCSV

        def write_csv(f, options = {})
          f.puts [ 'time', 'mean', 'standard_deviation' ].to_csv
          each do |time, mean, standard_deviation|
            f.puts [ time, mean, standard_deviation ].to_csv
          end
        end
      end
    end
  end
end
