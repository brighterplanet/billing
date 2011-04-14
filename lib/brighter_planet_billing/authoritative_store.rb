require 'mongo'

# TODO: add all indexes

module BrighterPlanet
  class Billing
    # An offsite mongo store.
    class AuthoritativeStore
      
      include ::Singleton
      
      delegate :find, :to => :collection
      delegate :find_one, :to => :collection
      delegate :distinct, :to => :collection
      delegate :update, :to => :collection
      
      # don't just delegate because counting with a spec requires a find in the middle
      def count(*args)
        spec, opts = args
        if spec
          collection.find(spec, (opts || {})).count
        else
          collection.count
        end
      end
      
      def upsert(execution_id, doc)
        doc ||= {}
        doc['execution_id'] = execution_id
        update({ 'execution_id' => execution_id }, doc, :upsert => true )
      end
      
      # _id_  _id
      # execution_id_1  execution_id    Delete_24px
      # year, month_1   year, month   false   Delete_24px
      # year_1  year  false   Delete_24px
      # month_1   month   false   Delete_24px
      # emitter_common_name_1   emitter_common_name   false   Delete_24px
      # key_1   key   false 
      INDEXES = [
        # [['execution_id', ::Mongo::ASCENDING]],
        [['emitter', ::Mongo::ASCENDING]],
        # [['service', ::Mongo::ASCENDING], ['year', ::Mongo::ASCENDING], ['month', ::Mongo::ASCENDING]]
      ]
      def create_indexes
        INDEXES.each { |index| collection.create_index index, :unique => false }
      rescue ::Mongo::OperationFailure
        # ignore, maybe a background process is running
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
      
      def collection
        return @collection if @collection.is_a? ::Mongo::Collection
        @collection = db.collection 'billables'
        @collection
      end
    end
  end
end
