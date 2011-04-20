require 'benchmark'
require 'bson'

module BrighterPlanet
  class Billing
    class Billable
      class << self
        autoload :Sample, 'brighter_planet_billing/billable/sample'
        
        def service
          raise ::RuntimeError, "[brighter_planet_billing] subclass of Billable must define .service"
        end
        
        # Find that acts like mongo
        def find(selector, opts = {})
          ary = []
          stream(selector, opts) { |billable| ary.push billable }
          ary
        end
      
        def find_one(selector, opts = {})
          if doc = Billing.storage.find_one(service.name, selector, opts)
            new doc
          end
        end
      
        # If you pass no args, it counts all docs
        # Otherwise you can pass selector and opts like find
        def count(*args)
          selector = args[0] || {}
          opts = args[1] || {}
          Billing.storage.count service.name, selector, opts
        end

        # Sort of like #each with finder args (selector and opts)
        def stream(selector, opts = {})
          Billing.storage.find(service.name, selector, opts).each do |doc|
            yield new(doc)
          end
        end

        def sample(selector, opts = {})
          Sample.new self, selector, opts
        end
        
        def bill(&blk)
          billable = new
          billable.bill &blk
          billable.save
          billable
        end
        
        # http://stackoverflow.com/questions/5723889/how-can-i-stringify-a-bson-object-inside-of-a-mongodb-map-function
        # http://stackoverflow.com/questions/5724086/why-is-mongodb-treating-these-two-keys-as-they-same
        # Billing.storage.distinct(service.name, field, selector)
        def top_values(num, field, selector, opts = {})
          selector = selector.symbolize_keys.reverse_merge field.to_sym => { '$exists' => true, '$nin' => [ '', nil, {} ]}
          opts = opts.symbolize_keys.merge :query => selector
          m = ::BSON::Code.new <<-EOS
            function() {
              emit(this.#{field}, 1);
            }
          EOS
          r = ::BSON::Code.new <<-EOS
            function(k, vals) {
              var sum=0;
              for (var i in vals) sum += vals[i];
              return sum;
            }
          EOS
          values = []
          Billing.storage.map_reduce(service.name, m, r, opts).find({}, :limit => num, :sort => [['value', ::Mongo::DESCENDING]]).each do |doc|
            values.push doc['_id']
          end
          values
        end
      end

      attr_accessor :year
      attr_accessor :month
      attr_accessor :key
      attr_accessor :remote_ip
      attr_accessor :referer
      attr_accessor :execution_id
      attr_accessor :started_at
      attr_accessor :stopped_at
      attr_accessor :succeeded
      attr_accessor :realtime

      attr_writer :hoptoad_error_id
      def hoptoad_error_id
        @hoptoad_error_id || @hoptoad_response
      end

      attr_writer :params
      def params
        (@params || @input_params).try :symbolize_keys
      end

      def initialize(doc = {})
        doc.each do |k, v|
          if respond_to? "#{k}="
            send "#{k}=", v
          else
            instance_variable_set "@#{k}", v
          end
        end
      end

      def service
        self.class.service
      end

      def mongo_id
        @_id
      end

      def save
        Billing.storage.save_execution service.name, execution_id, to_hash
      end
      
      def to_hash(*)
        instance_values.reject { |k, v| v.nil? }
      end
      
      def bill(&blk)
        self.execution_id = Billing.generate_execution_id
        now = ::Time.now
        self.year = now.year
        self.month = now.month
        self.started_at = now
        self.succeeded = false
        self.realtime = ::Benchmark.realtime { blk.call self } # where the magic happens
        self.succeeded = true
      rescue ::Exception => exception
        if Billing.config.disable_hoptoad or Billing.config.allowed_exceptions.any? { |exception_class| exception.is_a? exception_class }
          raise exception
        else
          if respond_to?(:gather_hoptoad_debugging_data) and hoptoad_error_id = ::HoptoadNotifier.notify_or_ignore(exception, gather_hoptoad_debugging_data)
            self.hoptoad_error_id = hoptoad_error_id
          end
          raise Billing::ReportedExceptionToHoptoad
        end
      ensure
        self.stopped_at = ::Time.now
        save
      end
    end
  end
end
