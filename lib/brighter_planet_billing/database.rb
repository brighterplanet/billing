module BrighterPlanet
  module Billing
    class Database
      include ::Singleton
      def put(execution_id, hsh)
        if Billing.config.slow_is_ok?
          Billing.authoritative_database.put execution_id, hsh
        else
          Billing.cache.put execution_id, hsh
        end
      end
      def each_key(&blk)
        Billing.authoritative_database.each_key &blk
      end
      def find_by_execution_id(execution_id)
        Billing.authoritative_database.find_by_execution_id execution_id
      end
      # should be "each query" or smth
      def each_by_key(key, year = nil, month = nil, &blk)
        Billing.authoritative_database.each_by_key key, year, month, &blk
      end
      def count
        Billing.authoritative_database.count
      end
      def count_by_month(year, month)
        Billing.authoritative_database.count_by_month year, month
      end
      def count_by_emitter(emitter)
        Billing.authoritative_database.count_by_emitter emitter
      end
      def count_by_key(key)
        Billing.authoritative_database.count_by_key key
      end
    end
  end
end
