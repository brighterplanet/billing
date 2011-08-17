module BrighterPlanet
  class Billing
    class Cm1
      autoload :Query, 'brighter_planet_billing/cm1/query'
      autoload :Trend, 'brighter_planet_billing/cm1/trend'
    
      include ::Singleton
    
      def name
        'Cm1'
      end
    
      def queries
        Query
      end
      
      alias :billables :queries
      
      delegate :bill, :to => :queries
    end
  end
end
