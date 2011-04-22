# http://stackoverflow.com/questions/5723889/how-can-i-stringify-a-bson-object-inside-of-a-mongodb-map-function
# http://stackoverflow.com/questions/5724086/why-is-mongodb-treating-these-two-keys-as-they-same
# Billing.storage.distinct(service.name, field, selector)
module BrighterPlanet
  class Billing
    class Billable
      class Top
        attr_reader :parent
        attr_reader :limit
        attr_reader :field
      
        # attrs:
        # * limit
        # * field
        # * selector
        def initialize(parent, attrs = {})
          @parent = parent
          attrs.each do |k, v|
            instance_variable_set "@#{k}", v
          end
        end
        
        include ::Enumerable

        def each
          parent.map_reduce(map_function, reduce_function, :query => selector_with_field_existence_checking).find({}, :limit => limit, :sort => [['value', ::Mongo::DESCENDING]]).each do |doc|
            yield doc['_id']
          end
        end
        
        def selector_with_field_existence_checking
          @selector.symbolize_keys.reverse_merge field.to_sym => { '$exists' => true }#, '$nin' => [ '', nil, {} ]}
        end
        
        alias :selector :selector_with_field_existence_checking
        
        def map_function
          ::BSON::Code.new <<-EOS
            function() {
              emit(this.#{field}, 1);
            }
          EOS
        end
        
        def reduce_function
          ::BSON::Code.new <<-EOS
            function(k, vals) {
              var sum=0;
              for (var i in vals) sum += vals[i];
              return sum;
            }
          EOS
        end
        
        include ToCSV
        
        def write_csv(f, options = {})
          f.puts [ 'field', 'field_DIGEST' ].to_csv
          each do |value|
            f.puts [ value.to_json, value.hash ].to_csv
          end
        end
      end
    end
  end
end
