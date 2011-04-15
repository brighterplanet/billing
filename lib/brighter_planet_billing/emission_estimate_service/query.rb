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
        attr_accessor :input
        attr_accessor :url
        attr_accessor :emitter
        attr_accessor :color
        attr_accessor :cm1_git_version
        attr_accessor :emitter_git_version
        
        attr_writer :emission
        def emission
          @emission.try :to_f
        end
        
        def gather_hoptoad_debugging_data
          # provide some things that hoptoad usually pulls from the controller or request
          opts = {}
          if input_params
            opts[:url] = input_params[:url]
            opts[:params] = input_params
            opts[:session] = input_params[:session]
          end
        end
      end
    end
  end
end
