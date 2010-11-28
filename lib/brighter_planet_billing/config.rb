module BrighterPlanet
  module Billing
    class Config
      include ::Singleton
      
      attr_writer :sdb_domain
      def sdb_domain
        @sdb_domain || ::ENV['BRIGHTER_PLANET_BILLING_SDB_DOMAIN']
      end

      attr_writer :aws_access_key_id
      def aws_access_key_id
        @aws_access_key_id || ::ENV['BRIGHTER_PLANET_BILLING_AWS_ACCESS_KEY_ID']
      end

      attr_writer :aws_secret_access_key
      def aws_secret_access_key
        @aws_secret_access_key || ::ENV['BRIGHTER_PLANET_BILLING_AWS_SECRET_ACCESS_KEY']
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
