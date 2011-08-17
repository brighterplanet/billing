module BrighterPlanet
  class Billing
    class Offsets
      autoload :Purchase, 'brighter_planet_billing/offsets/purchase'
    
      include ::Singleton
    
      def purchases
        Purchase
      end
      
      def service
        self.class.to_s.demodulize
      end
      
      alias :billables :purchases
      
      delegate :bill, :to => :purchases
    end
  end
end
