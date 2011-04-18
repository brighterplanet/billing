module BrighterPlanet
  class Billing
    class Storage
      
      include ::Singleton
      
      delegate :count, :to => :authoritative_store
      delegate :find_one, :to => :authoritative_store
      delegate :find, :to => :authoritative_store
      delegate :distinct, :to => :authoritative_store

      delegate :synchronized?, :to => :cache
      delegate :synchronize, :to => :cache
      
      def save_execution(service_name, execution_id, doc)
        if Billing.config.disable_caching?
          authoritative_store.save_execution service_name, execution_id, doc
        else
          cache.save_execution service_name, execution_id, doc
        end
      end

      private
      
      def authoritative_store
        Billing.authoritative_store
      end
      
      def cache
        Billing.cache
      end
    end
  end
end
