unless ::RUBY_VERSION >= '1.9'
  require 'system_timer'
end
require 'mongo'
# TODO: add all indexes

module BrighterPlanet
  class Billing
    # An offsite mongo store.
    class AuthoritativeStore

      include ::Singleton

      def find(service_name, selector, opts = {})
        if ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] == 'true' and selector != {}
          require 'pp'
          opts = opts.dup # mongo-ruby-driver borks input args
          cursor = collection(service_name).find(selector, opts)
          $stderr.puts "[brighter_planet_billing] EXPLAIN #{selector.to_json}"
          ::PP.pp cursor.explain, $stderr
          cursor.close
        end
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        collection(service_name).find selector, opts
      end

      def find_one(service_name, selector, opts = {})
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        collection(service_name).find_one selector, opts
      end

      def distinct(service_name, key, query = nil)
        collection(service_name).distinct key, query
      end

      # don't just delegate because counting with a selector requires a find in the middle
      def count(*args)
        service_name, selector, opts = args
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        if selector
          find(service_name, selector, opts).count
        else
          collection(service_name).count
        end
      end

      def map_reduce(service_name, m, r, opts = {}, &blk)
        tmp_collection_name = ::ActiveSupport::SecureRandom.hex 5
        tmp_collection = collection_on_primary(service_name).map_reduce(m, r, opts.symbolize_keys.merge(:out => tmp_collection_name))
        blk.call tmp_collection
      ensure
        tmp_collection.try :drop
      end

      def save_execution(service_name, execution_id, doc)
        doc = (doc || {}).symbolize_keys.merge(:execution_id => execution_id)
        selector = { :execution_id => execution_id }
        update(service_name, selector, doc, :upsert => true)
      end

      # Raw update... developers should generally use upsert
      def update(service_name, selector, document, opts = {})
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
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
          # [ [['key', ::Mongo::ASCENDING]], {} ],
          # [ [['execution_id', ::Mongo::ASCENDING]], {} ],
          # [ [['emitter', ::Mongo::ASCENDING]], {}],
          [ [['started_at', ::Mongo::ASCENDING]], { :unique => false, :background => true }],
          # [ [['params', ::Mongo::ASCENDING]], { :unique => false, :background => true }],
          [ [['emitter', ::Mongo::ASCENDING], ['key', ::Mongo::ASCENDING], ['execution_id', ::Mongo::ASCENDING]], { :unique => false, :background => true } ],
          [ [['emitter', ::Mongo::ASCENDING], ['key', ::Mongo::ASCENDING], ['params', ::Mongo::ASCENDING], ['execution_id', ::Mongo::ASCENDING]], { :unique => false, :background => true } ],
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

      def index_information(service_name)
        collection(service_name).index_information
      end

      private

      def connection
        @connection ||= ::Mongo::ReplSetConnection.new( [Billing.instance.config.mongo_host, Billing.instance.config.mongo_port],
                                                        [Billing.instance.config.mongo_arbiter_host, Billing.instance.config.mongo_arbiter_port],
                                                        :read_secondary => true )
      end

      def db
        return @db if @db.is_a? ::Mongo::DB
        @db = connection.db Billing.instance.config.mongo_database
        @db.authenticate Billing.instance.config.mongo_username, Billing.instance.config.mongo_password
        @db.strict = true
        @db
      end

      def collection(service_name)
        service_name = service_name.to_s
        @collection ||= {}
        return @collection[service_name] if @collection[service_name].is_a? ::Mongo::Collection
        @collection[service_name] = db.collection service_name.to_s
      end

      def connection_to_primary
        @connection_to_primary ||= ::Mongo::Connection.new Billing.instance.config.mongo_host, Billing.instance.config.mongo_port
      end

      def db_on_primary
        return @db_on_primary if @db_on_primary.is_a? ::Mongo::DB
        @db_on_primary = connection_to_primary.db Billing.instance.config.mongo_database
        @db_on_primary.authenticate Billing.instance.config.mongo_username, Billing.instance.config.mongo_password
        @db_on_primary.strict = true
        @db_on_primary
      end

      def collection_on_primary(service_name)
        service_name = service_name.to_s
        @collection_on_primary ||= {}
        return @collection_on_primary[service_name] if @collection_on_primary[service_name].is_a? ::Mongo::Collection
        @collection_on_primary[service_name] = db_on_primary.collection service_name.to_s
      end
    end
  end
end
