module BrighterPlanet
  class Billing
    # Rather surprisingly, we are using MySQL as a cache for docs that will eventually get saved to Mongo
    class Cache
      autoload :Document, 'brighter_planet_billing/cache/document.rb'
      
      include ::Singleton
      
      def synchronized?
        Document.untried.count.zero?
      end
      
      def save_execution(service_name, execution_id, doc)
        document = Document.find_or_create_by_execution_id execution_id
        document.update_attributes! :service_name => service_name.to_s, :content => doc
      end
      
      def synchronize
        until synchronized?
          document = Document.untried.first
          begin
            Billing.authoritative_store.save_execution document.service_name, document.execution_id, document.content
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
