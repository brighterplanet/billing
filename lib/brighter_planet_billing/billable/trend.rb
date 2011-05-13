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
          (@stats || [ :n_valid, :mean, :sd, :range ]).map(&:to_sym)
        end

        include ::Enumerable

        def each
          each_moment do |moment, moment_selector|
            yield [ moment ] + parent.sample(:selector => selector.merge(:started_at => moment_selector)).stats(field, *stats).values
          end
        end
                
        def columns
          [ :period_starting, stats ].flatten.map(&:to_sym)
        end

        include EachHash

        include ToCSV

        def write_csv(f)
          f.puts columns.to_csv
          each do |row|
            moment, *stats = row
            f.puts [ period_starting(moment), stats ].flatten.to_csv
          end
        end
      end
    end
  end
end
