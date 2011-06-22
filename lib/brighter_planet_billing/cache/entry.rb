require 'yajl'
require 'active_record'
require 'create_table'
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
        
        create_table do
          text :content
          string :service_name
          string :execution_id
          boolean :failed, :default => false
        end
        
        class << self
          def fast_create_by_service_name_and_execution_id_and_doc(service_name, execution_id, doc)
            entry = find_or_create_by_execution_id execution_id
            entry.service_name = service_name
            entry.doc = doc
            if ::ActiveRecord::VERSION::MAJOR >= 3
              entry.save :validate => false
            else
              entry.save false
            end
            entry
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
