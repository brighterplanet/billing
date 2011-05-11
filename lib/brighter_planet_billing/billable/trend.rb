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
        # * stats
        # # start_at / end_at / hours / days
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end

        def stats
          @stats || [ :n_valid, :mean, :sd, :range ]
        end

        def each
          each_moment do |moment, moment_selector|
            yield [ moment, parent.sample(:selector => selector.merge(:started_at => moment_selector)).stats(field, *stats).values ]
          end
        end

        include ToCSV

        def write_csv(f, options = {})
          f.puts [ 'period_starting', stats ].flatten.to_csv
          each do |time, stats|
            f.puts [ period_starting(time), stats ].flatten.to_csv
          end
        end
      end
    end
  end
end
