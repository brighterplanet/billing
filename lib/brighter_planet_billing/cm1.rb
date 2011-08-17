module BrighterPlanet
  class Billing
    class Cm1
      autoload :Query, 'brighter_planet_billing/cm1/query'
      autoload :Trend, 'brighter_planet_billing/cm1/trend'
    
      include ::Singleton
    
      def queries
        Query
      end
      
      def service
        self.class.to_s.demodulize
      end
      
      alias :billables :queries
      
      delegate :bill, :to => :queries
    end
  end
end
