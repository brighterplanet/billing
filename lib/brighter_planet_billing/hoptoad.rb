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
end
