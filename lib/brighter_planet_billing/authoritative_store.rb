unless ::RUBY_VERSION >= '1.9'
  require 'system_timer'
end
require 'mongo'
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

      def map_reduce(service_name, m, r, opts = {})
        output_collection = collection(service_name).map_reduce(m, r, opts.symbolize_keys.merge(:out => rand(10_000_000).to_s))
        # make sure everything is synced
        db.get_last_error(:w => 2)
        output_collection
      end

      def save_execution(service_name, execution_id, doc)
        doc = (doc || {}).symbolize_keys.merge(:execution_id => execution_id)
        selector = { :execution_id => execution_id }
        update(service_name, selector, doc, :upsert => true)
      end

      # Raw update... developers should generally use upsert
      def update(service_name, selector, doc, opts = {})
        opts = (opts || {}).dup # otherwise current version of mongo-ruby-driver borks input args
        collection(service_name).update selector, doc, opts
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
        @collection[service_name] = db.collection service_name
      end
    end
  end
end
