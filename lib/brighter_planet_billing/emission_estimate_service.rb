module BrighterPlanet
  class Billing
    class EmissionEstimateService
      autoload :Query, 'brighter_planet_billing/emission_estimate_service/query'
      autoload :SanityCheck, 'brighter_planet_billing/emission_estimate_service/sanity_check'
      autoload :Trend, 'brighter_planet_billing/emission_estimate_service/trend'
    
      include ::Singleton
    
      def name
        'EmissionEstimateService'
      end
    
      def queries
        Query
      end
      
      def sanity_check(host, key, selector)
        SanityCheck.new(host, key, selector).run
      end
      
      delegate :bill, :to => :queries
    end
  end
end
