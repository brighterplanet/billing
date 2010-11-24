require 'digest'
require 'singleton'
require 'active_support/core_ext/object/blank'
require 'active_support/json'
require 'brighter_planet_billing/hoptoad'
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
    def self.generate_execution_id(key)
      ::Digest::SHA256.hexdigest(key+::Time.now.to_f.to_s)
    end
  end
end
