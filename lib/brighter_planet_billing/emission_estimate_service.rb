module BrighterPlanet
  module Billing
    class EmissionEstimateService
      autoload :Key, 'brighter_planet_billing/emission_estimate_service/key'
      autoload :Query, 'brighter_planet_billing/emission_estimate_service/query'
      
      include ::Singleton
      
      def queries
        Query
      end
      
      def keys
        Key
      end
    end
  end
end
