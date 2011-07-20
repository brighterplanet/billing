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
    autoload :EmissionEstimateService, 'brighter_planet_billing/emission_estimate_service'
    autoload :ReferenceDataService, 'brighter_planet_billing/reference_data_service'

    include ::Singleton
    
    EXECUTION_ID_LENGTH = 20
    
    class << self
      def generate_execution_id
        ::ActiveSupport::SecureRandom.hex EXECUTION_ID_LENGTH
      end
    end
    
    def services
      [
        emission_estimate_service,
        reference_data_service
      ]
    end
    
    def keys
      Key
    end
    
    def emission_estimate_service
      EmissionEstimateService.instance
    end
    
    def reference_data_service
      ReferenceDataService.instance
    end
    
    def config
      Config.instance
    end
    
    def setup
      CacheEntry.force_schema!
    end
  end
end
