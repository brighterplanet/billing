if ::RUBY_VERSION >= '1.9'
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
      module ToCSV
        def as_csv_value(value)
          case value
          when ::Hash, ::Array
            value.to_json
          when ::Time, ::Date
            value.to_s :db
          else
            value
          end
        end
      
        # example arguments
        # to_csv()                            => returns a string
        # to_csv($stdout)                     => writes to $stdout
        def to_csv(f = :as_string)
          if f == :as_string
            as_string = true
            f = ::StringIO.new
          end

          write_csv f
                
          if as_string
            f.rewind
            return f.read
          end
      
          nil
        ensure
          f.try(:close) if as_string
        end
      end
    end
  end
end
