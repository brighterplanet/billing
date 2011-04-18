require 'rubygems'
require 'bundler'
Bundler.setup
require 'test/unit'
require 'active_support/all'
require 'active_record'
# thanks authlogic!
ActiveRecord::Schema.verbose = false
begin
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
rescue ArgumentError
  ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :dbfile => ":memory:")
end
$LOAD_PATH.unshift(File.dirname(__FILE__))
$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
require 'brighter_planet_billing'
::BrighterPlanet::Billing::Cache::Document.create_table
class Test::Unit::TestCase
  def setup
    ::BrighterPlanet::Billing.setup
    ::BrighterPlanet::Billing.config.disable_caching = false
    ::BrighterPlanet::Billing.config.disable_hoptoad = false
    ::BrighterPlanet::Billing.config.allowed_exceptions.clear
  end
end
