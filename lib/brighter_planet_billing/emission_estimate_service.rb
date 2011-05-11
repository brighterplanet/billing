module BrighterPlanet
  class Billing
    class EmissionEstimateService
      autoload :Query, 'brighter_planet_billing/emission_estimate_service/query'
      autoload :Trend, 'brighter_planet_billing/emission_estimate_service/trend'
    
      include ::Singleton
    
      def name
        'EmissionEstimateService'
      end
    
      def queries
        Query
      end
      
      alias :billables :queries
      
      delegate :bill, :to => :queries
    end
  end
end
