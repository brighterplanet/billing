require 'active_record'

# TODO: rename document to document

module BrighterPlanet
  class Billing
    class Cache
      class Document < ::ActiveRecord::Base
        set_table_name 'brighter_planet_billing_documents'
      
        serialize :content
      
        COLUMNS_HASH = {
          :content => :text,
          :service_name => :string,
          :execution_id => :string,
          :failed => :boolean,
        }
        COLUMN_OPTIONS = {
          :failed => { :default => false }
        }
        class << self
          def create_table
            if connection.table_exists?(table_name)
              COLUMNS_HASH.each do |k, v|
                unless columns_hash[k.to_s].type == v.to_sym
                  raise ::RuntimeError, "[brighter_planet_billing] need to drop and recreate billing table"
                end
              end
            else
              connection.create_table table_name do |t|
                COLUMNS_HASH.each do |k, v|
                  t.send v, k, (COLUMN_OPTIONS[k] || {})
                end
                t.timestamps
              end
              reset_column_information
            end
          end
        end
      
        if ::ActiveRecord::VERSION::MAJOR == 3
          def self.untried
            where arel_table[:failed].not_eq(true)
          end
        else
          named_scope :untried, :conditions => { :failed => false }
        end
      end
    end
  end
end
