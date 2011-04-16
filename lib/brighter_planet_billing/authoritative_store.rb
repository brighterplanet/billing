require 'mongo'

# TODO: add all indexes

module BrighterPlanet
  class Billing
    # An offsite mongo store.
    class AuthoritativeStore
      
      include ::Singleton
      
      def find(service_name, selector, opts = {})
        collection(service_name).find selector, opts
      end
      
      def find_one(service_name, selector, opts = {})
        collection(service_name).find_one selector, opts
      end
      
      def distinct(service_name, key, query = nil)
        collection(service_name).distinct key, query
      end
            
      # don't just delegate because counting with a selector requires a find in the middle
      def count(*args)
        service_name, selector, opts = args
        opts ||= {}
        if selector
          find(service_name, selector, opts).count
        else
          collection(service_name).count
        end
      end
      
      def save_execution(service_name, execution_id, doc)
        doc ||= {}
        doc.symbolize_keys!
        doc[:execution_id] = execution_id
        update(service_name, { :execution_id => execution_id }, doc, :upsert => true)
      end
      
      # Raw update... developers should generally use upsert
      def update(service_name, selector, document, opts = {})
        collection(service_name).update selector, document, opts
      end
      
      # _id_  _id
      # execution_id_1  execution_id    Delete_24px
      # year, month_1   year, month   false   Delete_24px
      # year_1  year  false   Delete_24px
      # month_1   month   false   Delete_24px
      # emitter_common_name_1   emitter_common_name   false   Delete_24px
      # key_1   key   false 
      INDEXES = {
        'EmissionEstimateService' => [
          # [['execution_id', ::Mongo::ASCENDING]],
          # [['emitter', ::Mongo::ASCENDING]],
          [ [['emitter', ::Mongo::ASCENDING], ['execution_id', ::Mongo::ASCENDING]], { :unique => false } ]
          # [['service', ::Mongo::ASCENDING], ['year', ::Mongo::ASCENDING], ['month', ::Mongo::ASCENDING]]
        ],
      }
      
      def create_indexes(service_name)
        service_name = service_name.to_s
        INDEXES[service_name].each do |index, opts|
          $stderr.puts "[brighter_planet_billing] Creating index (#{index.inspect}, #{opts.inspect}) on #{service_name}"
          collection(service_name).create_index index, opts
        end
      rescue ::Mongo::OperationFailure
        $stderr.puts "[brighter_planet_billing] Failed to create index: #{$!.inspect}"
      end

      private

      def connection
        @connection ||= ::Mongo::Connection.new Billing.config.mongo_host, Billing.config.mongo_port
      end
      
      def db
        return @db if @db.is_a? ::Mongo::DB
        @db = connection.db Billing.config.mongo_database
        @db.authenticate Billing.config.mongo_username, Billing.config.mongo_password
        @db
      end
      
      # since EmissionEstimateService's collection is currently called billable, we have to have a mapping
      ACTUAL_COLLECTION_NAMES = {
        'EmissionEstimateService' => 'billables', # legacy, this will change to EmissionEstimateService soon
        'ReferenceDataService' => 'ReferenceDataService',
      }
      
      def collection(service_name)
        service_name = service_name.to_s
        @collection ||= {}
        return @collection[service_name] if @collection[service_name].is_a? ::Mongo::Collection
        @collection[service_name] = db.collection ACTUAL_COLLECTION_NAMES[service_name]
      end
    end
  end
end
