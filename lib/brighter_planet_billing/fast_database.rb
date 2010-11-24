require 'active_record'

module BrighterPlanet
  module Billing
    class FastDatabase
      include ::Singleton
      def synchronized?
        Billable.count.zero?
      end
      def put(*args)
        Billable.create! :content => args
      end
      def synchronize
        until synchronized?
          billable = Billable.first
          Billing.authoritative_database.put *(billable.content)
          billable.destroy
        end
      end
      class Billable < ::ActiveRecord::Base
        set_table_name 'brighter_planet_billing_billables'
        serialize :content
        class << self
          def create_table
            unless connection.table_exists?('brighter_planet_billing_billables')
              connection.create_table 'brighter_planet_billing_billables' do |t|
                t.text :content
                t.timestamps
              end
              reset_column_information
            end
          end
        end
      end
    end
  end
end
        