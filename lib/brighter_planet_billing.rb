require 'digest'
require 'singleton'
require 'active_support/core_ext/object/blank'
require 'active_support/json'
require 'brighter_planet_billing/authoritative_store'
require 'brighter_planet_billing/emission_estimate_service'

module BrighterPlanet
  module Billing
    def self.authoritative_store
      AuthoritativeStore.instance
    end
    def self.emission_estimate_service
      EmissionEstimateService.instance
    end
    def self.generate_execution_id
      rand 1e64
    end
  end
end

# this has to go last because it overrides/configures hoptoad
require 'brighter_planet_billing/hoptoad'
