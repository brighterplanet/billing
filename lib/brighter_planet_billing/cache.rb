module BrighterPlanet
  class Billing
    # Rather surprisingly, we are using MySQL as a cache for docs that will eventually get saved to Mongo
    class Cache
      autoload :Entry, 'brighter_planet_billing/cache/entry.rb'
      
      include ::Singleton
      
      def synchronized?
        Entry.untried.count.zero?
      end
      
      def save_execution(service_name, execution_id, doc)
        Entry.fast_create_by_service_name_and_execution_id_and_doc service_name, execution_id, doc
      end
      
      def synchronize
        until synchronized?
          entry = Entry.untried.first
          begin
            Billing.instance.authoritative_store.save_execution entry.service_name, entry.execution_id, entry.doc
            entry.destroy
          rescue ::Exception => exception
            $stderr.puts exception.inspect
            entry.update_attribute :failed, true
          end
        end
      end
    end
  end
end
