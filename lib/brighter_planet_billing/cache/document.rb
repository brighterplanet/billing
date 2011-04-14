require 'active_record'

# TODO: rename document to document

module BrighterPlanet
  class Billing
    class Cache
      class Document < ::ActiveRecord::Base
        set_table_name 'brighter_planet_billing_documents'
      
        serialize :content
      
        class << self
          def create_table
            unless connection.table_exists?(table_name)
              connection.create_table table_name do |t|
                t.string :execution_id
                t.text :content
                t.boolean :failed, :default => false
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
