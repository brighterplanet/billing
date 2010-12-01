module BrighterPlanet
  module Billing
    class Config
      include ::Singleton

      attr_writer :mongo_host
      def mongo_host
        @mongo_host || ::ENV['BRIGHTER_PLANET_BILLING_MONGO_HOST']
      end
      
      attr_writer :mongo_port
      def mongo_port
        @mongo_port || ::ENV['BRIGHTER_PLANET_BILLING_MONGO_PORT']
      end
      
      attr_writer :mongo_database
      def mongo_database
        @mongo_database || ::ENV['BRIGHTER_PLANET_BILLING_MONGO_DATABASE']
      end
      
      attr_writer :mongo_username
      def mongo_username
        @mongo_username || ::ENV['BRIGHTER_PLANET_BILLING_MONGO_USERNAME']
      end
      
      attr_writer :mongo_password
      def mongo_password
        @mongo_password || ::ENV['BRIGHTER_PLANET_BILLING_MONGO_PASSWORD']
      end
      
      attr_writer :slow_is_ok
      def slow_is_ok
        @slow_is_ok || (::ENV['BRIGHTER_PLANET_BILLING_SLOW_IS_OK'] == 'true')
      end
      
      attr_writer :debug
      def debug
        @debug || (::ENV['BRIGHTER_PLANET_BILLING_DEBUG'] == 'true')
      end
      
      attr_writer :disable_hoptoad
      def disable_hoptoad
        @disable_hoptoad || (::ENV['BRIGHTER_PLANET_BILLING_DISABLE_HOPTOAD'] == 'true')
      end
      
      # prettier
      alias :slow_is_ok? :slow_is_ok
      alias :debug? :debug
      alias :disable_hoptoad? :disable_hoptoad
    end
  end
end
