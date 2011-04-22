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
    module ToCSV
      # example arguments
      # to_csv()                            => returns a string
      # to_csv($stdout)                     => writes to $stdout
      # to_csv(:foo => :bar)                => pass the option :foo => :bar
      # to_csv($stdout, :foo => :bar)       => ditto, to $stdout
      def to_csv(*args)
        f = if args.first.respond_to?(:puts)
          args.first
        else
          as_string = true
          ::StringIO.new
        end
      
        options = if args.last.is_a?(::Hash)
          args.last.symbolize_keys
        else
          {}
        end

        write_csv f, options
                
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
