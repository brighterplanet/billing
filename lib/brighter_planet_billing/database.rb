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
      def get(execution_id)
        Billing.authoritative_database.get execution_id
      end
    end
  end
end
