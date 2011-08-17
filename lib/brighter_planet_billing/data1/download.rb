module BrighterPlanet
  class Billing
    class Data1
      # The billable unit of data1 is a download
      # Currently we don't charge for it
      class Download < Billable
        class << self
          def service_model
            Data1.instance
          end
        end
        
        attr_accessor :resource
        attr_accessor :data1_version
        attr_accessor :earth_version
        attr_accessor :content_length
        attr_accessor :source
        attr_accessor :archived
        attr_accessor :line_count
      end
    end
  end
end
