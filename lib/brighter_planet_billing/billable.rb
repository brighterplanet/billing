require 'benchmark'
require 'bson'

module BrighterPlanet
  class Billing
    class Billable
      autoload :Sample, 'brighter_planet_billing/billable/sample'
      autoload :Trend, 'brighter_planet_billing/billable/trend'
      autoload :Top, 'brighter_planet_billing/billable/top'
      autoload :Usage, 'brighter_planet_billing/billable/usage'

      class << self
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
          if doc = Billing.instance.storage.find_one(service.name, selector, opts)
            new doc
          end
        end
      
        # If you pass no args, it counts all docs
        # Otherwise you can pass selector and opts like find
        def count(*args)
          selector = args[0] || {}
          opts = args[1] || {}
          Billing.instance.storage.count service.name, selector, opts
        end

        # Sort of like #each with finder args (selector and opts)
        def stream(selector, opts = {})
          Billing.instance.storage.find(service.name, selector, opts).each do |doc|
            yield new(doc)
          end
        end
        
        def map_reduce(m, r, opts = {}, &blk)
          Billing.instance.storage.map_reduce service.name, m, r, opts, &blk
        end

        def sample(attrs = {})
          Sample.new self, attrs
        end
        
        def trend(attrs = {})
          Trend.new self, attrs
        end
        
        def top(attrs = {})
          Top.new self, attrs
        end
        
        def usage(attrs = {})
          Usage.new self, attrs
        end
        
        def bill(&blk)
          billable = new
          billable.bill &blk
          billable.save
          billable
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
      attr_accessor :format
      attr_accessor :url
      attr_accessor :hoptoad_error_id
      attr_accessor :guid
      attr_accessor :async
      attr_accessor :callback

      attr_writer :params
      def params
        @params.try :symbolize_keys
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
        Billing.instance.storage.save_execution service.name, execution_id, to_hash
      end
      
      def to_hash(*)
        instance_values.reject { |k, v| v.nil? }
      end
      
      def bill(&blk)
        self.execution_id = ::ActiveSupport::SecureRandom.hex 20
        now = ::Time.now
        self.year = now.year
        self.month = now.month
        self.started_at = now
        self.succeeded = false
        self.realtime = ::Benchmark.realtime { blk.call self } # where the magic happens
        self.succeeded = true
      rescue ::Exception => exception
        if Billing.instance.config.disable_hoptoad or Billing.instance.config.allowed_exceptions.any? { |exception_class| exception.is_a? exception_class }
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
