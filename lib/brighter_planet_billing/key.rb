module BrighterPlanet
  class Billing
    # API key found in billing storage.
    class Key
      class << self
        def all
          Billing.instance.services.map do |service|
            Billing.instance.storage.distinct(service.name, :key).map do |key|
              new key.to_s
            end
          end.flatten.uniq
        end
      end
      
      attr_reader :key
      
      def initialize(key)
        @key = key
      end
      
      def hash
        key.hash
      end
      
      def eql?(other)
        key == other.key
      end
      alias :== :eql?
    end
  end
end
