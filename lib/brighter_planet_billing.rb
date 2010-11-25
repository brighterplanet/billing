require 'digest'
require 'singleton'
require 'active_support/core_ext/object/blank'
require 'active_support/json'
require 'brighter_planet_billing/hoptoad'
require 'brighter_planet_billing/database'
require 'brighter_planet_billing/fast_database'
require 'brighter_planet_billing/authoritative_database'
require 'brighter_planet_billing/emission_estimate_service'

module BrighterPlanet
  module Billing
    def self.synchronized?
      Billing.fast_database.synchronized?
    end
    def self.synchronize
      Billing.fast_database.synchronize
    end
    def self.database
      Database.instance
    end
    def self.fast_database
      FastDatabase.instance
    end
    def self.authoritative_database
      AuthoritativeDatabase.instance
    end
    def self.emission_estimate_service
      EmissionEstimateService.instance
    end
    def self.generate_execution_id
      rand 1e64
    end
  end
end

::HoptoadNotifier.configure do |config|
  unless config.ignore.include? ::BrighterPlanet::Billing::ReportedExceptionToHoptoad
    config.ignore.push ::BrighterPlanet::Billing::ReportedExceptionToHoptoad
  end
  # sabshere 7/1/10 just in case you want to send errors in development mode
  if ::BrighterPlanet::Billing.emission_estimate_service.disable_hoptoad?
    config.development_environments = [ ::Rails.env ]
  else
    # treat all environments as production - so development errors will be reported
    config.development_environments = []
  end
end
