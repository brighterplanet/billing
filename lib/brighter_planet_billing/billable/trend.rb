require 'stringio'
if RUBY_VERSION >= '1.9'
  require 'csv'
  ::BrighterPlanet::CSV = ::CSV
else
  begin
    require 'fastercsv'
    ::BrighterPlanet::CSV = ::FasterCSV
  rescue ::LoadError
    $stderr.puts "[brighter_planet_billing gem] You probably need to manually install the fastercsv gem and/or require it in your Gemfile."
    raise $!
  end
end

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
            
        def daily
          (Date.today.at_beginning_of_year..Date.today).each do |date|
            retval = [date] + parent.sample(:selector => selector.merge(:started_at => { '$gte' => date.to_time, '$lt' => date.tomorrow.to_time })).mean_and_standard_deviation(field)
            yield retval
          end
        end
      
        def aggregate_mean_and_standard_deviation
          parent.sample(:selector => selector.merge(:year => year)).mean_and_standard_deviation(field)
        end
      
        def to_csv
          f = ::StringIO.new
          f.puts [ 'selector', selector.inspect ].to_csv
          # params,{[...]/flights?origin_airport=jac&destination_airport=sfo[...]}
          f.puts [ 'field', field ].to_csv
          # field,emission
          f.puts
          #
          f.puts [ "#{year} daily" ].to_csv
          # 2011 daily
          f.puts [ 'date', 'mean', 'standard_deviation' ].to_csv
          # date, mean, standard_deviation
          daily do |date, mean, standard_deviation|
            f.puts [ date, mean, standard_deviation ].to_csv
          end
          # 2011-01-01,231.2,39.2
          f.puts
          #
          f.puts [ "#{year} aggregate" ].to_csv
          # 2011 aggregate
          f.puts [ 'mean', 'standard_deviation' ]
          # mean, standard_deviation
          f.puts aggregate_mean_and_standard_deviation.to_csv
          # 293.2, 291.2
          f.puts
          #
          # f.puts [ 'live' ].to_csv
          # # live
          # f.puts [ 'host', 'emission', 'difference_from_ytd_mean' ].to_csv
          # # host, emission, difference_from_ytd_mean
          # f.puts [ live_host, live_value, live_difference_from_aggregate_mean ].to_csv
          # # cm1-production-red.carbon.brighterplanet.com, 31.2
          f.rewind
          f.read
        ensure
          f.try :close
        end
      end
    end
  end
end
