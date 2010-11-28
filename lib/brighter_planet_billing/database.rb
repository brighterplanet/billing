module BrighterPlanet
  module Billing
    class Database
      include ::Singleton
      def put(execution_id, hsh)
        if Billing.config.slow_is_ok?
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
