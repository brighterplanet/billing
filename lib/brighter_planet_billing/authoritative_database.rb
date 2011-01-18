require 'mongo'

module BrighterPlanet
  module Billing
    class AuthoritativeDatabase
      include ::Singleton
      def count
        collection.count
      end
      def count_by_month(year, month)
        collection.find({"year" => year, "month" => month}).count
      end
      def count_by_emitter_common_name(emitter_common_name)
        collection.find({"emitter_common_name" => emitter_common_name}).count
      end
      def count_by_key(key)
        collection.find({"key" => key}).count
      end
      def conditions(key, year, month)
        if year and month
          { 'key' => key, 'year' => year.to_i, 'month' => month.to_i }
        elsif not year and not month
          { 'key' => key }
        else
          raise "don't know how to deal with (#{key}, #{year}, #{month})"
        end
      end
      def each_by_key(key, year = nil, month = nil, &blk)
        collection.find conditions(key, year, month) do |cursor|
          cursor.each do |doc|
            yield doc
          end
        end
      end
      def find_by_execution_id(execution_id)
        collection.find_one 'execution_id' => execution_id
      end
      def put(execution_id, hsh)
        hsh ||= {}
        hsh['execution_id'] = execution_id
        collection.update({ 'execution_id' => execution_id }, hsh, :upsert => true )
      end
      def connection
        @connection ||= ::Mongo::Connection.new ::BrighterPlanet::Billing.config.mongo_host, ::BrighterPlanet::Billing.config.mongo_port
      end
      def db
        return @db if @db.is_a? ::Mongo::DB
        @db = connection.db ::BrighterPlanet::Billing.config.mongo_database
        @db.authenticate ::BrighterPlanet::Billing.config.mongo_username, ::BrighterPlanet::Billing.config.mongo_password
        @db
      end
      def collection
        return @collection if @collection.is_a? ::Mongo::Collection
        @collection = db.collection 'billables'
        # @collection.ensure_index 'execution_id'
        @collection
      end
    end
  end
end

# if defined?(PhusionPassenger)
#   PhusionPassenger.on_event(:starting_worker_process) do |forked|
#     if forked
#       # Create new connection here
#     end
#   end
# end