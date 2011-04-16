require 'singleton'
require 'active_support'
require 'active_support/version'
if ::ActiveSupport::VERSION::MAJOR == 3
  require 'active_support/core_ext/module/delegation'
  require 'active_support/core_ext/object'
  require 'active_support/core_ext/hash'
  require 'active_support/core_ext/string/inflections'
  require 'active_support/json'
  require 'active_support/secure_random'
end

module BrighterPlanet
  class Billing
    autoload :Config, 'brighter_planet_billing/config'
    autoload :Storage, 'brighter_planet_billing/storage'
    autoload :Cache, 'brighter_planet_billing/cache'
    autoload :AuthoritativeStore, 'brighter_planet_billing/authoritative_store'
    autoload :Key, 'brighter_planet_billing/key'
    autoload :Billable, 'brighter_planet_billing/billable'
    autoload :Sample, 'brighter_planet_billing/sample'
    
    # services
    autoload :EmissionEstimateService, 'brighter_planet_billing/emission_estimate_service'
    
    include ::Singleton
    
    class ReportedExceptionToHoptoad < RuntimeError; end
    
    def self.emission_estimate_service
      EmissionEstimateService.instance
    end
    
    def self.config
      Config.instance
    end
    
    def self.storage
      Storage.instance
    end
    
    def self.cache
      Cache.instance
    end
    
    def self.authoritative_store
      AuthoritativeStore.instance
    end
    
    def self.setup
      Cache::Document.create_table
      ::HoptoadNotifier.configure do |hoptoad_config|
        unless hoptoad_config.ignore.include? ::BrighterPlanet::Billing::ReportedExceptionToHoptoad
          hoptoad_config.ignore.push ::BrighterPlanet::Billing::ReportedExceptionToHoptoad
        end
      end
    end
    
    def self.generate_execution_id
      ::ActiveSupport::SecureRandom.hex 20
    end
    
    def self.synchronized?
      storage.synchronized?
    end
    
    def self.synchronize
      storage.synchronize
    end
  end
end

require 'hoptoad_notifier'
module HoptoadNotifier
  class Sender
    # Return the response object so that we can later parse out the URL to the hoptoad error
    #--
    # sabshere 4/12/11 verified this is compatible with 2.4.9
    # def log(level, message, response = nil)
    #   logger.send level, LOG_PREFIX + message if logger
    #   HoptoadNotifier.report_environment_info
    #   HoptoadNotifier.report_response_body(response.body) if response && response.respond_to?(:body)
    # end
    def log_with_returning_response(level, message, response = nil)
      log_without_returning_response level, message, response
      response
    end
    alias_method :log_without_returning_response, :log
    alias_method :log, :log_with_returning_response
  end
end
