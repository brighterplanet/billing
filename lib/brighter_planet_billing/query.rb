require 'benchmark'

# TODO: move execute?
# TODO: unlock from EmissionEstimateService
# TODO: fix camelcase/underscore for emitter and service

module BrighterPlanet
  class Billing
    class Query
      class << self
        def execute(&blk)
          query = new
          query.execute &blk
          query.save
        end

        delegate :count, :to => :documents

        def find(spec, opts = {})
          documents.find(spec, opts).map do |doc|
            new doc
          end
        end
        
        def find_one(spec, opts = {})
          find(spec, opts)[0]
        end
                  
        # Gives a supposedly representative sample of queries for this emitter across all time.
        def sample(emitter, size = 1)
          (2010..::Time.now.year).inject([]) do |memo, year|
            (1..12).each do |month|
              # :service => 'EmissionEstimateService'
              Billing.documents.find({:emitter_common_name => emitter.underscore, :year => year, :month => month}, :limit => size).each do |attrs|
                memo.push new(attrs)
              end
            end
            memo
          end
        end
        
        private
        
        def documents
          Billing.documents
        end
      end

      attr_accessor :year
      attr_accessor :month
      attr_accessor :certified
      attr_accessor :key
      attr_accessor :input_params
      attr_accessor :url
      attr_accessor :emitter_common_name
      attr_accessor :remote_ip
      attr_accessor :referer
      attr_accessor :output_params
      attr_accessor :execution_id
      attr_accessor :started_at
      attr_accessor :stopped_at
      attr_accessor :hoptoad_response
      attr_accessor :succeeded
      attr_accessor :realtime

      def initialize(attrs = {})
        attrs.each do |k, v|
          if respond_to? "#{k}="
            send "#{k}=", v
          else
            instance_variable_set "@#{k}", v
          end
        end
        @service = 'EmissionEstimateService'
      end

      def mongo_id
        @_id
      end

      # fixme
      def emitter=(emitter)
        @emitter_common_name = emitter.underscore
      end

      # fixme
      def emitter
        @emitter_common_name.camelcase
      end

      # fixme
      def service=(service)
        @service = service.underscore
      end

      # fixme
      def service
        @service.camelcase
      end

      def save
        Billing.documents.upsert execution_id, to_hash
      end
      
      def to_hash
        as_json
      end

      CSV_HEADERS = %w{
        year
        month
        service
        certified
        key
        input_params
        url
        emitter
        remote_ip
        referer
        output_params
        execution_id
        started_at
        stopped_at
        hoptoad_response
        succeeded
        realtime
      }
      def to_csv
        CSV_HEADERS.map do |k|
          v = send k
          '"' + v.to_json.gsub('"', '""') + '"'
        end.join(',')
      end

      def execute(&blk)
        self.execution_id = Billing.generate_execution_id
        now = ::Time.now
        self.year = now.year
        self.month = now.month
        self.started_at = now
        self.hoptoad_response = nil
        self.succeeded = false
        self.realtime = ::Benchmark.realtime { yield self }
        self.succeeded = true
      rescue ::Exception => exception
        if Billing.config.disable_hoptoad or Billing.config.allowed_exceptions.any? { |exception_class| exception.is_a? exception_class }
          raise exception
        else
          # provide some things that hoptoad usually pulls from the controller or request
          opts = {}
          if input_params
            opts[:url] = input_params[:url]
            opts[:params] = input_params
            opts[:session] = input_params[:session]
          end
          if hoptoad_container = ::HoptoadNotifier.notify_or_ignore(exception, opts)
            self.hoptoad_response = hoptoad_container.body
          end
          raise Billing::ReportedExceptionToHoptoad
        end
      ensure
        self.emitter_common_name = emitter_common_name
        self.stopped_at = ::Time.now
        save
      end
    end
  end
end
