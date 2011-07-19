require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'active_support/all'
require 'active_record'
require 'timeframe'
require 'pp'
# thanks authlogic!
ActiveRecord::Schema.verbose = false
begin
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
rescue ArgumentError
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
end

# require 'logger'
# ActiveRecord::Base.logger = Logger.new($stderr)
# ActiveRecord::Base.logger.level = Logger::DEBUG

$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'brighter_planet_billing'
class Test::Unit::TestCase
  def setup
    ::BrighterPlanet.billing.setup
    ::BrighterPlanet.billing.config.disable_caching = false
  end
end

Time.zone = 'Eastern Time (US & Canada)'
