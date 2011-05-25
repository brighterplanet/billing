require 'yajl'
require 'active_record'
module BrighterPlanet
  class Billing
    class Cache
      class Entry < ::ActiveRecord::Base
        set_table_name 'brighter_planet_billing_documents'
      
        def doc
          ::Yajl::Parser.parse read_attribute(:content)
        end
        
        def doc=(obj)
          write_attribute :content, ::Yajl::Encoder.encode(obj)
        end
      
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
          def fast_create_by_service_name_and_execution_id_and_doc(service_name, execution_id, doc)
            entry = find_or_create_by_execution_id execution_id
            entry.service_name = service_name
            entry.doc = doc
            entry.save false
            entry
          end
          
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
