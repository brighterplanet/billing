require 'aws'

module BrighterPlanet
  module Billing
    class AuthoritativeDatabase
      include ::Singleton
      attr_writer :aws_access_key_id
      attr_writer :aws_secret_access_key
      attr_writer :sdb_domain
      def sdb_domain
        @sdb_domain || ::ENV['BRIGHTER_PLANET_BILLING_SDB_DOMAIN']
      end
      def aws_access_key_id
        @aws_access_key_id || ::ENV['BRIGHTER_PLANET_BILLING_AWS_ACCESS_KEY_ID']
      end
      def aws_secret_access_key
        @aws_secret_access_key || ::ENV['BRIGHTER_PLANET_BILLING_AWS_SECRET_ACCESS_KEY']
      end
      def prep_result_hash(hsh)
        hsh.inject({}) do |memo, subhsh|
          k, ary = subhsh
          v = ary[0]
          memo[k] = ::ActiveSupport::JSON.decode v.to_s
          memo
        end
      end
      def prep_search_param(str)
        ::ActiveSupport::JSON.encode str.to_s
      end
      def find_all_by_key(key)
        results = []
        sdb.select ["select * from #{sdb_domain} where key = ?", prep_search_param(key)] do |partial_results|
          partial_results[:items].each do |item|
            results.push prep_result_hash(item.values[0])
          end
        end
        results
      end
      def find_by_execution_id(execution_id)
        result = sdb.get_attributes sdb_domain, execution_id
        return if result[:attributes].empty?
        prep_result_hash result[:attributes]
      end
      def put(execution_id, hsh)
        hsh = hsh.dup
        hsh.each do |k, v|
          hsh[k] = v.to_json
        end
        sdb.put_attributes sdb_domain, execution_id, hsh, true
      end
      def sdb
        return @sdb if @sdb.is_a? ::Aws::SdbInterface
        @sdb = ::Aws::SdbInterface.new aws_access_key_id, aws_secret_access_key, :connection_mode => :per_thread
        @sdb.create_domain sdb_domain
        @sdb
      end
    end
  end
end
