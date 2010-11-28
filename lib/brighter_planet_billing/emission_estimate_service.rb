require 'benchmark'
require 'blockenspiel'

module BrighterPlanet
  module Billing
    class EmissionEstimateService
      include ::Singleton
      def queries
        Query
      end
      def keys
        Key
      end
      class Key
        class << self
          def find_by_key(key)
            new key
          end
        end
        attr_reader :key
        def initialize(key)
          @key = key
        end
        def each_query(&blk)
          Billing.database.each_by_key(key) do |hsh|
            yield Query.from_hash(hsh)
          end
        end
      end
      class Query
        class << self
          def start(&blk)
            query = new
            ::Blockenspiel.invoke blk, query
            raise "You need to call #execute inside of the start {} block!" if Billing.config.debug? and not query.executed?
            query.save
          end
          def find_by_execution_id(execution_id)
            if hsh = Billing.database.find_by_execution_id(execution_id)
              from_hash hsh
            end
          end
          def from_hash(hsh)
            query = new
            hsh.each do |k, v|
              query.send "#{k}=", v
            end
            query
          end
        end
        attr_accessor :service
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
        attr_accessor :session
        def initialize
          @service = 'emission_estimate_service'
        end

        def save
          Billing.database.put execution_id, to_hash
        end

        def to_hash
          instance_variables.inject({}) do |memo, ivar_name|
            memo[ivar_name.to_s.sub('@','')] = instance_variable_get ivar_name
            memo
          end
        end
        
        CSV_HEADERS = %w{
          service
          key
          input_params
          url
          emitter_common_name
          remote_ip
          referer
          output_params
          execution_id
          started_at
          stopped_at
          hoptoad_response
          succeeded
          realtime
          session
        }
        def to_csv
          CSV_HEADERS.map do |k|
            v = send k
            '"' + v.to_s.gsub('"', '\"') + '"'
          end.join(',')
        end

        def executed?
          !!execution_id
        end

        def execute(&blk)
          raise "You can only call #execute once inside of the start {} block!" if Billing.config.debug? and query.executed?
          self.execution_id = Billing.generate_execution_id
          self.started_at = ::Time.now
          self.hoptoad_response = nil
          self.succeeded = false
          self.realtime = ::Benchmark.realtime { blk.call }
          self.succeeded = true
        rescue ::Exception => exception
          if Billing.config.disable_hoptoad
            raise exception
          else
            # provide some things that hoptoad usually pulls from the controller or request
            opts = {}
            if input_params
              opts[:url] = input_params[:url]
              opts[:params] = input_params
              opts[:session] = input_params[:session]
            end
            self.hoptoad_response = ::HoptoadNotifier.notify_or_ignore(exception, opts).body
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
end
