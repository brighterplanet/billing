require 'benchmark'

module BrighterPlanet
  module Billing
    class EmissionEstimateService
      class Query
        class << self
          def execute(&blk)
            query = new
            query.execute &blk
            query.save
          end
          
          def find_by_execution_id(execution_id)
            if hsh = Billing.database.find_by_execution_id(execution_id)
              from_hash hsh
            end
          end
          
          def count
            Billing.database.count
          end
          
          def count_by_emitter(emitter)
            Billing.database.count_by_emitter emitter
          end
          
          # deprecated
          def count_by_emitter_common_name(emitter_common_name)
            Billing.database.count_by_emitter emitter_common_name.camelcase
          end
          
          def count_by_key(key)
            Billing.database.count_by_key key
          end
          
          def count_by_month(year, month)
            Billing.database.count_by_month year, month
          end
          
          def from_hash(hsh)
            query = new
            hsh.each do |k, v|
              next if k == '_id'
              begin
                query.send "#{k}=", v
              rescue ::NoMethodError
              end
            end
            query
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

        def initialize
          @service = 'EmissionEstimateService'
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
          Billing.database.put execution_id, to_hash
        end

        def to_hash
          instance_variables.inject({}) do |memo, ivar_name|
            memo[ivar_name.to_s.sub('@','')] = instance_variable_get ivar_name
            memo
          end
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
end
