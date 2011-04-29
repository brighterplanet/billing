require 'timeframe'

module BrighterPlanet
  class Billing
    class EmissionEstimateService
      # The billable unit of the emission estimate service is a query
      class Query < Billable
        class << self
          def service
            EmissionEstimateService.instance
          end
        end
        
        attr_accessor :certified
        attr_accessor :methodology
        attr_accessor :color
        attr_accessor :cm1_version
        attr_accessor :emitter_version
        
        attr_accessor :compliance

        attr_writer :emitter
        def emitter
          @emitter || @emitter_common_name.try(:camelcase)
        end
        
        attr_writer :emission
        def emission
          @emission || @output_params.try(:symbolize_keys).try(:[], :emission)
        end
        
        attr_reader :timeframe_from
        attr_reader :timeframe_to
        def timeframe
          ::Timeframe.new timeframe_from, timeframe_to, :skip_year_boundary_crossing_check => true
        end
        def timeframe=(timeframe)
          @timeframe_from = timeframe.from.to_time
          @timeframe_to = timeframe.to.to_time
          timeframe
        end
        
        def gather_hoptoad_debugging_data
          # provide some things that hoptoad usually pulls from the controller or request
          debug = {}
          if params
            debug[:url] = params[:url]
            debug[:params] = params
            debug[:session] = params[:session]
          end
          debug
        end
      end
    end
  end
end
