module BrighterPlanet
  class Billing
    # API key found in billing documents.
    class Key
      class << self
        def find(spec, opts = {})
          Billing.documents.find(spec, opts).map do |doc|
            new doc
          end
        end
        
        def find_one(spec, opts = {})
          find(spec, opts)[0]
        end

        def all
          Billing.documents.distinct(:key).map do |key|
            new key.to_s
          end
        end
      end
      
      attr_reader :key
      
      def initialize(key)
        @key = key
      end
      
      def each_query
        Billing.documents.find(:key => key) do |cursor|
          cursor.each do |doc|
            yield Query.new(doc)
          end
        end
      end
    end
  end
end
