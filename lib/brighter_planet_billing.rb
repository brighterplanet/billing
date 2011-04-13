require 'singleton'
require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR == 3
  require 'active_support/core_ext/object/blank'
  require 'active_support/core_ext/string/inflections'
  require 'active_support/json'
  require 'active_support/secure_random'
end
require 'brighter_planet_billing/config'
require 'brighter_planet_billing/hoptoad'
require 'brighter_planet_billing/database'
require 'brighter_planet_billing/cache'
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
    def self.cache
      Cache.instance
    end
    def self.authoritative_database
      AuthoritativeDatabase.instance
    end
    def self.emission_estimate_service
      EmissionEstimateService.instance
    end
    def self.setup
      Cache::Billable.create_table
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
      cache.synchronized?
    end
    def self.synchronize
      cache.synchronize
    end
  end
end
