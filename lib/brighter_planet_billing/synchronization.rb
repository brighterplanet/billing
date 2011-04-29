module BrighterPlanet
  class Billing
    # for use with Resque
    #
    # e.g. Resque.enqueue BrighterPlanet::Billing::Synchronization
    class Synchronization
      class << self
        def perform
          ActiveRecord::Base.connection.reconnect!
          Billing.synchronize
        end
        
        attr_writer :queue
        def queue
          @queue || :high
        end
      end
    end
  end
end
   