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
  BrighterPlanet::Billing.config.disable_caching = true
  BrighterPlanet::Billing.config.disable_hoptoad = true
end

# stats

namespace :index do
  task :list => :setup do
    require 'pp'
    PP.pp BrighterPlanet::Billing.authoritative_store.index_information(ENV['S'] || 'EmissionEstimateService'), $stderr
  end

  task :create => :setup do
    BrighterPlanet::Billing.authoritative_store.create_indexes(ENV['S'] || 'EmissionEstimateService')
  end
end

namespace :emission_estimate_service do
  task :clean1 => :setup do
    require 'brighter_planet_metadata'
    BrighterPlanet.metadata.emitters.each do |emitter|
      puts
      puts emitter
      puts BrighterPlanet::Billing.authoritative_store.update('EmissionEstimateService', {:emitter_common_name=>emitter.underscore, :emitter=>{'$exists'=>false}}, {'$set'=>{:emitter=>emitter}}, :safe => false, :upsert => false, :multi => true)
    end
  end
  
  task :clean2 => :setup do
    count = 0
    BrighterPlanet::Billing.emission_estimate_service.queries.stream({:output_params=>{'$exists'=>true}}) do |query|
      changed = false
      if emitter_common_name = query.instance_variable_get(:@emitter_common_name) and query.emitter != emitter_common_name.camelcase
        query.emitter = emitter_common_name.camelcase
        changed = true
      end
      if output_params = query.instance_variable_get(:@output_params) and output_params.is_a?(::Hash)
        query.emission = output_params.symbolize_keys[:emission].to_f
        query.instance_variable_set :@output_params, nil
        changed = true
      end
      if params = query.instance_variable_get(:@input_params) and params.is_a?(::Hash)
        query.params = params.symbolize_keys
        query.instance_variable_set :@input_params, nil
        changed = true
      end
      if changed
        query.save
        if ((count+=1) % 500) == 0
          $stderr.puts "fixed #{count} (example: #{query.execution_id})"
        end
      end
    end
  end
end
