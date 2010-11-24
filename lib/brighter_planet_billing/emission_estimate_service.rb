require 'benchmark'
require 'blockenspiel'

module BrighterPlanet
  module Billing
    class EmissionEstimateService
      include ::Singleton
      def queries
        Query
      end
      class Query
        class << self
          def create(&blk)
            query = new
            ::Blockenspiel.invoke blk, query
            raise "You need to call #execute inside of the record {} block!" unless query.executed?
            query.save
          end
          def by_execution_id(execution_id)
            from_hash Billing.authoritative_store.get(execution_id)
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

        def initialize
          @service = 'emission_estimate_service'
        end

        def save
          Billing.authoritative_store.put execution_id, to_hash
        end

        def to_hash
          instance_variables.inject({}) do |memo, ivar_name|
            memo[ivar_name.to_s.sub('@','')] = instance_variable_get ivar_name
            memo
          end
        end

        def executed?
          !!execution_id
        end

        def execute(&blk)
          self.execution_id = Billing.generate_execution_id key
          self.started_at = ::Time.now
          self.hoptoad_response = nil
          self.succeeded = false
          self.realtime = ::Benchmark.realtime { blk.call }
          self.succeeded = true
        rescue ::Exception => exception
          if defined?(::DISABLE_HOPTOAD) and ::DISABLE_HOPTOAD == true
            raise exception
          else
            # provide some things that hoptoad usually pulls from the controller or request
            opts = {
              :url => input_params[:url],
              :params => input_params,
              :session => input_params[:session]
            }
            self.hoptoad_response = ::HoptoadNotifier.notify_or_ignore(exception, opts).body
            raise ::BrighterPlanet::Billing::ReportedExceptionToHoptoad
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
