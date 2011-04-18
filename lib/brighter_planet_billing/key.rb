module BrighterPlanet
  class Billing
    # API key found in billing storage.
    class Key
      class << self
        def find(selector, opts = {})
          Billing.storage.find(selector, opts).map do |doc|
            new doc
          end
        end
        
        def find_one(selector, opts = {})
          find(selector, opts)[0]
        end

        def all
          Billing.storage.distinct(:key).map do |key|
            new key.to_s
          end
        end
      end
      
      attr_reader :key
      
      def initialize(key)
        @key = key
      end
      
      def each_billable
        raise "each service..."
        Billing.storage.find(:key => key).each do |cursor|
          yield Billable.new(doc)
        end
      end
    end
  end
end
