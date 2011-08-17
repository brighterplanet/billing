require 'singleton'
require 'stringio'
require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR >= 3
  require 'active_support/core_ext'
  require 'active_support/json'
  require 'active_support/secure_random'
end

module BrighterPlanet
  def self.billing
    Billing.instance
  end
  
  class Billing
    autoload :Config, 'brighter_planet_billing/config'
    autoload :CacheEntry, 'brighter_planet_billing/cache_entry'
    autoload :AuthoritativeStore, 'brighter_planet_billing/authoritative_store'
    autoload :Key, 'brighter_planet_billing/key'
    autoload :Billable, 'brighter_planet_billing/billable'
    autoload :Synchronization, 'brighter_planet_billing/synchronization'
    
    # services
    autoload :Cm1, 'brighter_planet_billing/cm1'
    autoload :Data1, 'brighter_planet_billing/data1'
    autoload :Offsets, 'brighter_planet_billing/offsets'

    include ::Singleton
    
    EXECUTION_ID_LENGTH = 20
    
    class << self
      def generate_execution_id
        ::ActiveSupport::SecureRandom.hex EXECUTION_ID_LENGTH
      end
    end
    
    def service_models
      [
        cm1,
        data1
      ]
    end
    
    def services
      service_models.map(&:service)
    end
    
    def keys
      Key
    end
    
    def cm1
      Cm1.instance
    end
    
    def data1
      Data1.instance
    end

    def offsets
      Offsets.instance
    end
    
    def config
      Config.instance
    end
    
    def setup
      CacheEntry.force_schema!
    end
  end
end
