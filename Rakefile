require 'bundler'
Bundler::GemHelper.install_tasks

require 'rake'
require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

task :default => :test

task :setup do
  Bundler.setup
  $LOAD_PATH.unshift(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
  require 'brighter_planet_billing'
  
end

task :fix_emitters => :setup do
  require 'brighter_planet_metadata'
  BrighterPlanet.metadata.emitters.each do |emitter|
    puts
    puts emitter
    puts BrighterPlanet::Billing.authoritative_store.update({ :emitter_common_name => emitter.underscore }, { '$set' => {:emitter => emitter} }, :safe => true)#, :multi => true)
    exit
  end
end

task :create_indexes => :setup do
  BrighterPlanet::Billing.authoritative_store.create_indexes
end
