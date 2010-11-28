module BrighterPlanet
  module Billing
    class Database
      include ::Singleton
      attr_writer :slow_is_ok
      def slow_is_ok
        @slow_is_ok || (::ENV['BRIGHTER_PLANET_BILLING_SLOW_IS_OK'] == 'true')
      end
      alias :slow_is_ok? :slow_is_ok
      def put(execution_id, hsh)
        if slow_is_ok?
          Billing.authoritative_database.put execution_id, hsh
        else
          Billing.fast_database.put execution_id, hsh
        end
      end
      def find_by_execution_id(execution_id)
        Billing.authoritative_database.find_by_execution_id execution_id
      end
      def find_all_by_key(key)
        Billing.authoritative_database.find_all_by_key key
      end
    end
  end
end
