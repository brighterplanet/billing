module BrighterPlanet
  class Billing
    class EmissionEstimateService
      autoload :Query, 'brighter_planet_billing/emission_estimate_service/query'
    
      include ::Singleton
    
      def name
        'EmissionEstimateService'
      end
    
      def queries
        Query
      end
      
      delegate :bill, :to => :queries
    end
  end
end
