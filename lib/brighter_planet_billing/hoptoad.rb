# This has to happen here because otherwise hoptoad_notifier is loaded last and reverts my changes
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

module BrighterPlanet
  module Billing
    class ReportedExceptionToHoptoad < RuntimeError; end
  end
end
