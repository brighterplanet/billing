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
        attr_accessor :emitter
        attr_accessor :emission
        attr_accessor :input_interpretation
        
        def timeframe_from
          @timeframe_from.is_a?(::Time) ? @timeframe_from : @timeframe_from.try(:to_time)
        end
        
        def timeframe_to
          @timeframe_to.is_a?(::Time) ? @timeframe_to : @timeframe_to.try(:to_time)
        end
        
        def timeframe
          ::Timeframe.new timeframe_from, timeframe_to, :skip_year_boundary_crossing_check => true
        end
        def timeframe=(timeframe)
          @timeframe_from = timeframe.from.to_time
          @timeframe_to = timeframe.to.to_time
          timeframe
        end
      end
    end
  end
end
