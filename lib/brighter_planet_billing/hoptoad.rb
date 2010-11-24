# This has to happen here because otherwise hoptoad_notifier is loaded last and reverts my changes
require 'hoptoad_notifier'
module HoptoadNotifier
  class Sender
    # Return the response object so that we can later parse out the URL to the hoptoad error
    def log_with_returning_response(level, message, response = nil)
      log_without_returning_response level, message, response
      response
    end
    alias_method :log_without_returning_response, :log
    alias_method :log, :log_with_returning_response
  end
end

module BrighterPlanet
  module Billing
    class ReportedExceptionToHoptoad < RuntimeError; end
  end
end

::HoptoadNotifier.configure do |config|
  unless config.ignore.include? ::BrighterPlanet::Billing::ReportedExceptionToHoptoad
    config.ignore.push ::BrighterPlanet::Billing::ReportedExceptionToHoptoad
  end
  # sabshere 7/1/10 just in case you want to send errors in development mode
  if ::ENV['BRIGHTER_PLANET_BILLING_DISABLE_HOPTOAD'] == true
    config.development_environments = [ ::Rails.env ]
  else
    # treat all environments as production - so development errors will be reported
    config.development_environments = []
  end
end
