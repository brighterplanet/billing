require 'benchmark'

module BrighterPlanet
  class Billing
    class Billable
      autoload :Sample, 'brighter_planet_billing/billable/sample'
      autoload :Trend, 'brighter_planet_billing/billable/trend'
      autoload :Top, 'brighter_planet_billing/billable/top'
      autoload :Usage, 'brighter_planet_billing/billable/usage'
      
      # mixins
      autoload :TimeAttrs, 'brighter_planet_billing/billable/time_attrs'
      autoload :ToCSV, 'brighter_planet_billing/billable/to_csv'
      autoload :EachHash, 'brighter_planet_billing/billable/each_hash'

      class << self
        def service
          raise ::RuntimeError, "[brighter_planet_billing] subclass of Billable must define .service"
        end
        
        def collection_name
          service.class.to_s.demodulize
        end
        
        # Find that acts like mongo
        def find(selector, opts = {})
          ary = []
          stream(selector, opts) { |billable| ary.push billable }
          ary
        end
      
        def find_one(selector, opts = {})
          if doc = Billing::AuthoritativeStore.instance.find_one(collection_name, selector, opts)
            new doc
          end
        end
      
        # If you pass no args, it counts all docs
        # Otherwise you can pass selector and opts like find
        def count(*args)
          selector = args[0] || {}
          opts = args[1] || {}
          Billing::AuthoritativeStore.instance.count collection_name, selector, opts
        end

        # Sort of like #each with finder args (selector and opts)
        def stream(selector, opts = {})
          Billing::AuthoritativeStore.instance.find(collection_name, selector, opts).each do |doc|
            yield new(doc)
          end
        end
        
        def map_reduce(m, r, opts = {})
          Billing::AuthoritativeStore.instance.map_reduce collection_name, m, r, opts
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
      attr_accessor :succeeded
      attr_accessor :realtime
      attr_accessor :format
      attr_accessor :url
      attr_accessor :guid
      attr_accessor :async
      attr_accessor :callback

      attr_writer :input
      def input
        @input.try :symbolize_keys
      end

      attr_writer :started_at
      def started_at
        @started_at.is_a?(::Time) ? @started_at : @started_at.try(:to_time)
      end

      attr_writer :stopped_at
      def stopped_at
        @stopped_at.is_a?(::Time) ? @stopped_at : @stopped_at.try(:to_time)
      end
      
      def initialize(hsh = {})
        import_hash hsh
      end

      def service
        self.class.service
      end
      
      def collection_name
        self.class.collection_name
      end

      def mongo_id
        @_id
      end

      def save(force_authoritative = false)
        if force_authoritative or Billing::Config.instance.disable_caching?
          Billing::AuthoritativeStore.instance.upsert_billable self
        else
          Billing::CacheEntry.upsert_billable self
        end
      end
      
      WITHOUT_AT_SIGN = 1..-1
      def marshal_dump(*)
        instance_variables.inject({}) do |memo, ivar_name|
          k = ivar_name.to_s[WITHOUT_AT_SIGN].to_sym
          unless (v = respond_to?(k) ? send(k) : instance_variable_get(ivar_name)).nil?
            memo[k] = v
          end
          memo
        end
      end
      alias :to_hash :marshal_dump
      
      def marshal_load(memo)
        memo.each do |k, v|
          if respond_to? "#{k}="
            send "#{k}=", v
          else
            instance_variable_set("@#{k}", v) unless v.nil?
          end
        end
      end
      alias :import_hash :marshal_load
      
      def bill(&blk)
        self.execution_id = Billing.generate_execution_id
        now = ::Time.now.utc
        self.year = now.year
        self.month = now.month
        self.started_at = now
        self.succeeded = false
        self.realtime = ::Benchmark.realtime { blk.call self } # where the magic happens
        self.succeeded = true
      ensure
        self.stopped_at = ::Time.now.utc
        save
      end
    end
  end
end
