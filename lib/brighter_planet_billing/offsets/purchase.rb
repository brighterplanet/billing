module BrighterPlanet
  class Billing
    class Offsets
      # The billable unit of CM1 is a query
      class Purchase < Billable
        class << self
          def service_model
            Offsets.instance
          end
        end
        
        attr_accessor :price
        attr_accessor :co2
      end
    end
  end
end
