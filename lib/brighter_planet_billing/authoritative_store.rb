require 'aws'

module BrighterPlanet
  module Billing
    class AuthoritativeStore
      include ::Singleton
      attr_writer :aws_access_key_id
      attr_writer :aws_secret_access_key
      attr_writer :sdb_domain
      def sdb_domain
        @domain || ::ENV['BRIGHTER_PLANET_BILLING_SDB_DOMAIN']
      end
      def aws_access_key_id
        @aws_access_key_id || ::ENV['BRIGHTER_PLANET_BILLING_AWS_ACCESS_KEY_ID']
      end
      def aws_secret_access_key
        @aws_secret_access_key || ::ENV['BRIGHTER_PLANET_BILLING_AWS_SECRET_ACCESS_KEY']
      end
      def get(execution_id)
        sdb.get_attributes(domain, execution_id)[:attributes].inject({}) do |memo, hsh|
          k, ary = hsh
          v = ary[0]
          memo[k] = ::ActiveSupport::JSON.decode v.to_s
          memo
        end
      end
      def put(execution_id, hsh)
        hsh = hsh.dup
        hsh.each do |k, v|
          hsh[k] = v.to_json
        end
        sdb.put_attributes domain, execution_id, hsh, true
      end
      def sdb
        return @sdb if @sdb.is_a? ::Aws::SdbInterface
        @sdb = ::Aws::SdbInterface.new aws_access_key_id, aws_secret_access_key
        @sdb.create_domain domain
        @sdb
      end
    end
  end
end
