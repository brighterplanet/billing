module BrighterPlanet
  class Billing
    class ImpactEstimateService
      autoload :Query, 'brighter_planet_billing/impact_estimate_service/query'
      autoload :Trend, 'brighter_planet_billing/impact_estimate_service/trend'
    
      include ::Singleton
    
      def name
        'ImpactEstimateService'
      end
    
      def queries
        Query
      end
      
      alias :billables :queries
      
      delegate :bill, :to => :queries
    end
  end
end
