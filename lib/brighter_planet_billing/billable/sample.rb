require 'statsample'

module BrighterPlanet
  class Billing
    class Billable
      class Sample
        attr_reader :parent
        attr_reader :fields
      
        # attrs
        # * selector
        # * limit
        # * fields
        # * digest
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end
        
        # using execution_id as a random attribution
        # thanks http://cookbook.mongodb.org/patterns/random-attribute/
        # ('2'*40) corresponds to 1/8 or 12.50% sample
        RANDOM_ATTRIBUTE_THRESHOLD = '2' * Billing::EXECUTION_ID_LENGTH
        
        # 10,000 datapoints should be enough
        LIMIT = 10_000

        def selector_with_random_attribute_threshold
          with_random_attribute_threshold = @selector.symbolize_keys.merge :execution_id => { '$lte' => RANDOM_ATTRIBUTE_THRESHOLD }
          if parent.count(with_random_attribute_threshold) > 1
            with_random_attribute_threshold
          else
            @selector
          end
        end
        
        alias :selector :selector_with_random_attribute_threshold
      
        def limit
          [ @limit, LIMIT ].compact.min
        end

        def digest
          ::Array.wrap(@digest).map(&:to_sym)
        end
        
        include ::Enumerable
        
        def each
          parent.stream(selector, :limit => limit) do |billable|
            yield billable
          end
        end
        
        def columns
          (@columns || digest.map { |field| "#{field}_DIGEST" } + fields).map(&:to_sym)
        end
        
        # include EachHash
        def each_hash
          each do |billable|
            yield billable.to_hash
          end
        end

        include ToCSV

        def write_csv(f)
          first_row = true
          each_hash do |row| # treating rows as hashes so that we can re-order them
            if first_row
              # if we didn't get fields before, then we'll get them from the first row
              @fields ||= row.keys.sort
              f.puts columns.to_csv
              first_row = false
            end
            values = columns.map do |field|
              if field.to_s.end_with?('_DIGEST')
                row[field.to_s.sub('_DIGEST', '').to_sym].hash
              else
                as_csv_value row[field]
              end
            end
            f.puts values.to_csv
          end
        end
        
        # a different set of methods, like if you wanted to run stats in ruby
        
        # sd, mean, n_valid, range
        def stats(*args)
          field = args.shift
          v = vector field
          args.inject({}) do |memo, f|
            memo[f] = begin; v.send(f); rescue; nil; end
            memo
          end
        end
        
        def vector(field)
          ary = []
          each do |billable|
            if datapoint = billable.send(field)
              ary.push datapoint.to_f
            end
          end
          ary.to_scale
        end
      end
    end
  end
end
