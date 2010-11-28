require 'digest'
require 'singleton'
require 'active_support/core_ext/object/blank'
require 'active_support/json'
require 'brighter_planet_billing/config'
require 'brighter_planet_billing/hoptoad'
require 'brighter_planet_billing/database'
require 'brighter_planet_billing/fast_database'
require 'brighter_planet_billing/authoritative_database'
require 'brighter_planet_billing/emission_estimate_service'

module BrighterPlanet
  module Billing
    def self.config
      Config.instance
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
    def self.setup
      FastDatabase::Billable.create_table
      ::HoptoadNotifier.configure do |hoptoad_config|
        unless hoptoad_config.ignore.include? ReportedExceptionToHoptoad
          hoptoad_config.ignore.push ReportedExceptionToHoptoad
        end
        # sabshere 7/1/10 just in case you want to send errors in development mode
        if defined?(::Rails) and config.disable_hoptoad?
          hoptoad_config.development_environments = [ ::Rails.env ]
        else
          # treat all environments as production - so development errors will be reported
          hoptoad_config.development_environments = []
        end
      end
    end
    # Hashing this makes a pretty key that everyone will treat as a string (instead of a number)
    def self.generate_execution_id
      ::Digest::SHA256.hexdigest rand(1e64).to_s
    end
    def self.synchronized?
      fast_database.synchronized?
    end
    def self.synchronize
      fast_database.synchronize
    end
  end
end
