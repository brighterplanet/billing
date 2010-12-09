require 'singleton'
require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR == 3
  require 'active_support/core_ext/object/blank'
  require 'active_support/json'
  require 'active_support/secure_random'
end
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
      end
    end
    def self.generate_execution_id
      ::ActiveSupport::SecureRandom.hex 40
    end
    def self.synchronized?
      fast_database.synchronized?
    end
    def self.synchronize
      fast_database.synchronize
    end
  end
end
