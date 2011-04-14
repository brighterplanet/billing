module BrighterPlanet
  class Billing
    class Documents
      
      include ::Singleton
      
      def upsert(execution_id, doc)
        if Billing.config.disable_caching?
          authoritative_store.upsert execution_id, doc
        else
          cache.upsert execution_id, doc
        end
      end
            
      delegate :count, :to => :authoritative_store
      delegate :find_one, :to => :authoritative_store
      delegate :find, :to => :authoritative_store
      delegate :distinct, :to => :authoritative_store
      
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
