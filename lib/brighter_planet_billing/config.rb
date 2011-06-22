module BrighterPlanet
  class Billing
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
      
      attr_writer :mongo_arbiter_host
      def mongo_arbiter_host
        @mongo_arbiter_host || ::ENV['BRIGHTER_PLANET_BILLING_MONGO_ARBITER_HOST'] || 27017
      end
      
      attr_writer :mongo_arbiter_port
      def mongo_arbiter_port
        @mongo_arbiter_port || ::ENV['BRIGHTER_PLANET_BILLING_MONGO_ARBITER_PORT'] || 27017
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
      
      attr_writer :disable_caching
      def disable_caching
        @disable_caching || (::ENV['BRIGHTER_PLANET_BILLING_DISABLE_CACHING'] == 'true')
      end
      
      attr_writer :debug
      def debug
        @debug || (::ENV['BRIGHTER_PLANET_BILLING_DEBUG'] == 'true')
      end
      
      # prettier
      alias :disable_caching? :disable_caching
      alias :debug? :debug
    end
  end
end
