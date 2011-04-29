module BrighterPlanet
  class Billing
    class ReferenceDataService
      autoload :Download, 'brighter_planet_billing/reference_data_service/download'
    
      include ::Singleton
    
      def name
        'ReferenceDataService'
      end
    
      def downloads
        Download
      end
      
      alias :billables :downloads
            
      delegate :bill, :to => :downloads
    end
  end
end
