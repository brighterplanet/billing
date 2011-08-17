module BrighterPlanet
  class Billing
    class Data1
      autoload :Download, 'brighter_planet_billing/data1/download'
    
      include ::Singleton
    
      def downloads
        Download
      end
      
      def service
        self.class.to_s.demodulize
      end
      
      alias :billables :downloads
            
      delegate :bill, :to => :downloads
    end
  end
end
