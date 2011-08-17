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
  BrighterPlanet.billing.config.disable_caching = true
end

# stats

namespace :cm1 do
  task :re_save => :setup do
    count = 0
    started_at_is_a_string = { 'started_at' => { '$type' => 2 } }
    BrighterPlanet.billing.cm1.queries.stream(started_at_is_a_string) do |query|
      query.save
      if ((count+=1) % 500) == 0
        $stderr.puts "fixed #{count} (example: #{query.execution_id})"
      end
    end
  end

  # task :camelcase_emitter => :setup do
  #   require 'brighter_planet_metadata'
  #   BrighterPlanet.metadata.emitters.each do |emitter|
  #     puts
  #     puts emitter
  #     puts BrighterPlanet::Billing::AuthoritativeStore.instance.update('Cm1', {:emitter_common_name=>emitter.underscore, :emitter=>{'$exists'=>false}}, {'$set'=>{:emitter=>emitter}}, :safe => true, :upsert => false, :multi => true)
  #   end
  # end
  # 
  # task :retire_input_input => :setup do
  #   count = 0
  #   BrighterPlanet.billing.cm1.queries.stream({:input_input=>{'$exists'=>true}}) do |query|
  #     changed = false
  #     # if emitter_common_name = query.instance_variable_get(:@emitter_common_name) and query.emitter != emitter_common_name.camelcase
  #     #   query.emitter = emitter_common_name.camelcase
  #     #   changed = true
  #     # end
  #     if query.instance_variable_defined?(:@output_input)
  #       output_input = query.instance_variable_get(:@output_input)
  #       if output_input.is_a?(::Hash)
  #         query.impact = output_input.symbolize_keys[:impact].to_f
  #         query.instance_variable_set :@output_input, nil
  #       end
  #       changed = true
  #     end
  #     if query.instance_variable_defined?(:@input_input)
  #       input = query.instance_variable_get(:@input_input)
  #       if input.is_a?(::Hash)
  #         query.input = input.symbolize_keys
  #         query.instance_variable_set :@input_input, nil
  #       end
  #       changed = true
  #     end
  #     if changed
  #       query.save
  #       if ((count+=1) % 500) == 0
  #         $stderr.puts "fixed #{count} (example: #{query.execution_id})"
  #       end
  #     end
  #   end
  # end
end
