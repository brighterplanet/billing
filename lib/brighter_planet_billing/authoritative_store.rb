unless ::RUBY_VERSION >= '1.9'
  require 'system_timer'
end
require 'mongo'
module BrighterPlanet
  class Billing
    # An offsite mongo store.
    class AuthoritativeStore

      include ::Singleton

      def find(collection_name, selector, opts = {})
        if ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] == 'true' and selector != {}
          require 'pp'
          opts = opts.dup # mongo-ruby-driver borks input args
          cursor = collection(collection_name).find(selector, opts)
          $stderr.puts "[brighter_planet_billing] EXPLAIN #{selector.to_json}"
          ::PP.pp cursor.explain, $stderr
          cursor.close
        end
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        collection(collection_name).find selector, opts
      end

      def find_one(collection_name, selector, opts = {})
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        collection(collection_name).find_one selector, opts
      end

      def distinct(collection_name, key, query = nil)
        collection(collection_name).distinct key, query
      end

      # don't just delegate because counting with a selector requires a find in the middle
      def count(*args)
        collection_name, selector, opts = args
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        if selector
          find(collection_name, selector, opts).count
        else
          collection(collection_name).count
        end
      end

      def map_reduce(collection_name, m, r, opts = {})
        output_collection = collection(collection_name).map_reduce(m, r, opts.symbolize_keys.merge(:out => rand(10_000_000).to_s))
        # make sure everything is synced
        db.get_last_error(:w => 2)
        output_collection
      end

      def upsert_billable(billable)
        doc = (doc || {}).symbolize_keys.merge(:execution_id => billable.execution_id)
        selector = { :execution_id => billable.execution_id }
        update billable.collection_name, selector, billable.to_hash, :upsert => true
      end

      # Raw update... developers should generally use upsert
      def update(collection_name, selector, doc, opts = {})
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        collection(collection_name).update selector, doc, opts
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
        @db
      end

      def collection(collection_name)
        collection_name = collection_name.to_s
        @collection ||= {}
        return @collection[collection_name] if @collection[collection_name].is_a? ::Mongo::Collection
        @collection[collection_name] = db.collection collection_name
      end
    end
  end
end
