module BrighterPlanet
  module Billing
    class EmissionEstimateService
      class Key
        class << self
          def find_by_key(key)
            new key
          end
          def all
            ary = []
            Billing.database.each_key do |key|
              ary << new(key.to_s)
            end
            ary
          end
        end
        
        attr_reader :key
        
        def initialize(key)
          @key = key
        end
        
        def each_query(year = nil, month = nil, &blk)
          Billing.database.each_by_key(key, year, month) do |hsh|
            yield Query.from_hash(hsh)
          end
        end
      end
    end
  end
end
