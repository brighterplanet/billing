module BrighterPlanet
  class Billing
    # Rather surprisingly, we are using MySQL as a cache for docs that will eventually get saved to Mongo
    class Cache
      autoload :Document, 'brighter_planet_billing/cache/document.rb'
      
      include ::Singleton
      
      def synchronized?
        Document.untried.count.zero?
      end
      
      def upsert(execution_id, doc)
        document = Document.find_or_create_by_execution_id execution_id
        document.update_attributes! :content => doc
      end
      
      def synchronize
        until synchronized?
          document = Document.untried.first
          begin
            Billing.authoritative_store.upsert document.execution_id, document.content
            document.destroy
          rescue ::Exception => exception
            $stderr.puts exception.inspect
            document.update_attributes! :failed => true
          end
        end
      end
    end
  end
end
