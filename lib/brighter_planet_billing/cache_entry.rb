require 'yajl'
require 'active_record'
require 'force_schema'
module BrighterPlanet
  class Billing
    class CacheEntry < ::ActiveRecord::Base
      set_table_name 'brighter_planet_billing_cache_entries'

      force_schema do
        text :serialized_content
        string :collection_name
        string :execution_id
        boolean :failed, :default => false
      end
      
      if ::ActiveRecord::VERSION::MAJOR >= 3
        def self.untried
          where arel_table[:failed].not_eq(true)
        end
      else
        named_scope :untried, :conditions => { :failed => false }
      end

      def content
        ::Yajl::Parser.parse read_attribute(:serialized_content)
      end

      def content=(obj)
        write_attribute :serialized_content, ::Yajl::Encoder.encode(obj)
      end

      class << self
        def synchronized?
          untried.count.zero?
        end

        def synchronize
          until synchronized?
            entry = untried.first
            begin
              billable = Billing.const_get(entry.collection_name).instance.billables.new entry.content.merge(:execution_id => entry.execution_id)
              billable.save true
              entry.destroy
            rescue ::Exception => exception
              $stderr.puts exception.inspect
              entry.update_attribute :failed, true
            end
          end
        end
        
        def upsert_billable(billable)
          entry = find_or_create_by_execution_id billable.execution_id
          entry.collection_name = billable.collection_name
          entry.content = billable.to_hash
          if ::ActiveRecord::VERSION::MAJOR >= 3
            entry.save :validate => false
          else
            entry.save false
          end
          entry
        end
      end
    end
  end
end
