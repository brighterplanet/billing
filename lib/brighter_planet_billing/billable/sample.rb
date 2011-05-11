require 'statsample'

module BrighterPlanet
  class Billing
    class Billable
      class Sample
        attr_reader :parent
      
        # attrs
        # * selector
        # * limit
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set "@#{k}", v
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

        include ToCSV

        def write_csv(f, options = {})
          first_row = true
          fields = options[:fields]
          each do |doc|
            row = doc.as_json
            if first_row
              # if we didn't get fields defined in the options, then we'll get them from the first row
              fields ||= row.keys.sort
              # add any digest fields
              ::Array.wrap(options[:digest]).each do |field|
                fields.unshift "#{field}_DIGEST"
              end
              f.puts fields.to_csv
              first_row = false
            end
            values = fields.map do |field|
              if field.end_with?('_DIGEST')
                row[field.sub('_DIGEST', '')].hash
              else
                as_csv_value row[field]
              end
            end
            f.puts values.to_csv
          end
        end
        
        def each
          parent.stream(selector, :limit => limit) do |billable|
            yield billable
          end
        end
        
        # a different set of methods, like if you wanted to run stats in ruby
        
        def mean(field)
          vector(field).mean
        end
      
        def standard_deviation(field)
          vector(field).sd
        end
        
        # faster than doing separately
        def mean_and_standard_deviation(field)
          v = vector(field)
          mean = begin; v.mean; rescue; $!.inspect; end
          sd = begin; v.sd; rescue; $!.inspect; end
          [ mean, sd ]
        end
        
        def vector(field)
          ary = []
          each do |billable|
            if datapoint = billable.send(field).to_f
              ary.push datapoint
            end
          end
          ary.to_scale
        end
      end
    end
  end
end
