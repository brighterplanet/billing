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
          moment = start_at
          while moment < end_at
            mean, standard_deviation = parent.sample(:selector => selector.merge(:started_at => { '$gte' => moment, '$lt' => (moment + precision) })).mean_and_standard_deviation(field)
            yield [ moment.dup, mean, standard_deviation ]
            moment += precision
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
