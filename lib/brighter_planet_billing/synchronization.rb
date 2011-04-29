module BrighterPlanet
  class Billing
    # for use with Resque
    #
    # e.g. Resque.enqueue BrighterPlanet::Billing::Synchronization
    class Synchronization
      @queue = :high
      
      class << self
        def perform
          ActiveRecord::Base.connection.reconnect!
          Billing.synchronize
        end
      end
    end
  end
end
   