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
        attr_accessor :url
        attr_accessor :emitter
        attr_accessor :color
        attr_accessor :cm1_git_version
        attr_accessor :emitter_git_version
        attr_accessor :emission
        
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
