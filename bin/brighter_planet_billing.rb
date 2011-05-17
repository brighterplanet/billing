#!/usr/bin/env ruby

unless RUBY_VERSION >= '1.9'
  require 'rubygems'
end

if File.exist?(File.join(Dir.pwd, 'brighter_planet_billing.gemspec'))
  require 'bundler'
  Bundler.setup
  $LOAD_PATH.unshift(File.dirname(__FILE__))
  $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
end

require 'brighter_planet_billing'
require 'thor'
require 'to_regexp'

module BrighterPlanet
  class Billing
    class CLI < ::Thor
      desc "cheat", "copy-paste some useful command examples"
      def cheat
        $stdout.puts %{
Hint: eval `./secrets.sh` (get secrets.sh from Seamus)
Hint: do a "> foo.csv" and import into Excel

High level stuff:
  #{__FILE__} top_params --limit 5 --emitter=Flight --key=${TEST_KEY}

Low-level stuff:
  #{__FILE__} top --limit=5 --field=params --selector="{ emitter: 'Flight', key: '${TEST_KEY}' }"
  #{__FILE__} sample --limit 5 --fields=emitter started_at params emission --digest params --selector="{ emitter: 'Flight', key: '${TEST_KEY}', 'params.destination_airport': 'MCO' }"
  #{__FILE__} trend --days=5 --field=emission --selector="{ emitter: 'Flight', key: '${TEST_KEY}', 'params.destination_airport': 'MCO' }"
  #{__FILE__} usage --months=6 --key=${TEST_KEY}
}
      end
      
      desc "top_params", "shortcut to getting the top params for a certain emitter and key"
      method_option :emitter, :type => :string, :required => true
      method_option :key, :type => :string, :required => true
      method_option :limit, :type => :numeric
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      def top_params
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        top_params = Billable::Top.new service_model.billables, :field => 'params', :selector => options.slice(:emitter, :key), :limit => options[:limit]
        top_params.to_csv $stdout
      end
      
      desc "top", "get the top values for a certain field"
      method_option :field, :type => :string
      method_option :selector, :type => :string
      method_option :limit, :type => :numeric
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      def top
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        top = Billable::Top.new service_model.billables, options.slice(:field, :limit).merge(:selector => selector_from_json)
        top.to_csv $stdout
      end
      
      desc "sample", "get a representative sample based on a query"
      method_option :limit, :type => :numeric
      method_option :digest, :type => :array, :description => "Include a digest (hashcode) for these columns to make it easy to sort. Useful for columns that contain hashes."
      method_option :selector, :type => :string
      method_option :fields, :type => :array
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      method_option :period, :type => :string
      method_option :start_at, :type => :string
      method_option :end_at, :type => :string
      method_option :hours, :type => :numeric
      method_option :minutes, :type => :numeric
      method_option :days, :type => :numeric
      method_option :weeks, :type => :numeric
      method_option :months, :type => :numeric
      def sample
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        if ary = options[:fields] and ary.first.include?(',')
          $stderr.puts "WARNING: commas seen in field definition, separate with spaces instead"
        end
        sample = Billable::Sample.new service_model.billables, options.slice(:limit, :fields, :digest).merge(time_attrs).merge(:selector => selector_from_json)
        sample.to_csv $stdout
      end
      
      desc "trend", "get stats of a certain field"
      method_option :field, :type => :string
      method_option :selector, :type => :string
      method_option :stats, :type => :array, :default => Billable::Trend::DEFAULT_STATS
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      method_option :period, :type => :string
      method_option :start_at, :type => :string
      method_option :end_at, :type => :string
      method_option :hours, :type => :numeric
      method_option :minutes, :type => :numeric
      method_option :days, :type => :numeric
      method_option :weeks, :type => :numeric
      method_option :months, :type => :numeric
      def trend
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        trend = Billable::Trend.new service_model.billables, options.slice(:field, :stats).merge(time_attrs).merge(:selector => selector_from_json)
        trend.to_csv $stdout
      end
      
      desc "usage", "get usage"
      method_option :key, :type => :string, :required => true
      method_option :include_failed, :type => :boolean, :default => false
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      method_option :selector, :type => :string
      method_option :period, :type => :string
      method_option :start_at, :type => :string
      method_option :end_at, :type => :string
      method_option :hours, :type => :numeric
      method_option :minutes, :type => :numeric
      method_option :days, :type => :numeric
      method_option :weeks, :type => :numeric
      method_option :months, :type => :numeric
      def usage
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        usage = Billable::Usage.new service_model.billables, options.slice(:include_failed).merge(time_attrs).merge(:selector => options.slice(:key).reverse_merge(selector_from_json))
        usage.to_csv $stdout
      end
      
      private
      
      def time_attrs
        hsh = options.slice(:hours, :minutes, :days, :weeks, :months, :start_at, :end_at)
        hsh[:period] = eval(options[:period]).to_i if options[:period] # 1.minute turns into 60
        hsh
      end
      
      def service_model
        Billing.const_get(options[:service]).instance
      end
      
      def selector_from_json
        return {} if options[:selector].blank?
        hsh = ::ActiveSupport::JSON.decode options[:selector]
        raise ::ArgumentError, "Selector must be a JSON hash like { foo: 'bar' }" unless hsh.is_a?(::Hash)
        hsh.inject({}) do |memo, (k, v)|
          memo[k] = if v.is_a?(::Date)
            v.to_time
          elsif v.respond_to?(:to_regexp) and r = v.to_regexp
            r
          else
            v
          end
          memo
        end
      end
    end
  end
end

BrighterPlanet::Billing::CLI.start
