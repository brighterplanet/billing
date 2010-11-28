require 'aws'

module BrighterPlanet
  module Billing
    class AuthoritativeDatabase
      include ::Singleton
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
      def each_by_key(key, &blk)
        sdb.select ["select * from #{Billing.config.sdb_domain} where key = ?", prep_search_param(key)] do |partial_results|
          partial_results[:items].each do |item|
            yield prep_result_hash(item.values[0])
          end
        end
      end
      def find_by_execution_id(execution_id)
        result = sdb.get_attributes Billing.config.sdb_domain, execution_id
        return if result[:attributes].empty?
        prep_result_hash result[:attributes]
      end
      def put(execution_id, hsh)
        hsh = hsh.dup
        hsh.each do |k, v|
          hsh[k] = v.to_json
        end
        sdb.put_attributes Billing.config.sdb_domain, execution_id, hsh, true
      end
      def sdb
        return @sdb if @sdb.is_a? ::Aws::SdbInterface
        @sdb = ::Aws::SdbInterface.new Billing.config.aws_access_key_id, Billing.config.aws_secret_access_key, :connection_mode => :per_thread
        @sdb.create_domain Billing.config.sdb_domain
        @sdb
      end
    end
  end
end
