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

module BrighterPlanet
  class Billing
    class CLI < ::Thor
      desc "cheat", "copy-paste some useful command examples"
      def cheat
        $stdout.puts %{
Hint: eval `./secrets.sh` (get secrets.sh from Seamus)
Hint: do a "> foo.csv" and import into Excel

High level stuff:
  #{__FILE__} params --limit 5 --emitter=Flight --key=${TRIPCARBON_KEY}

Low-level stuff:
  #{__FILE__} sample --limit 5 --fields=emitter started_at params emission --digest params --selector="{ emitter: 'Flight', key: '${TRIPCARBON_KEY}', 'params.destination_airport': 'MCO' }"
  #{__FILE__} trend --field=emission --selector="{ emitter: 'Flight', key: '${TRIPCARBON_KEY}', 'params.destination_airport': 'MCO' }"
}
# TOP
# #{__FILE__} top --limit=5 --field=params --selector=emitter:Flight key:${TRIPCARBON_KEY}
      end
      
      desc "params", "get the top params for a certain emitter and key"
      method_option :emitter, :type => :string, :required => true
      method_option :key, :type => :string, :required => true
      method_option :limit, :type => :numeric, :default => 5
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      def params
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        Billable::Top.new(service.billables, :field => 'params', :selector => options.slice(:emitter, :key), :limit => options[:limit]).each do |p|
          $stdout.puts flatten_selector(options.slice(:emitter, :key).merge(:params => p)).to_json.gsub(%{"}, %{'})
        end
      end
      
      desc "sample", "get a representative sample based on a query"
      method_option :limit, :type => :numeric, :default => Billable::Sample::LIMIT
      method_option :digest, :type => :array, :description => "Include a digest (hashcode) for these columns to make it easy to sort. Useful for columns that contain hashes."
      method_option :selector, :type => :string
      method_option :fields, :type => :array
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      def sample
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        if ary = options[:fields] and ary.first.include?(',')
          $stderr.puts "WARNING: commas seen in field definition, separate with spaces instead"
        end
        Billable::Sample.new(service.billables, options.slice(:limit).merge(:selector => selector)).to_csv($stdout, options.slice(:fields, :digest))
      end
      
      desc "trend", "get a daily average and standard deviation of a certain field"
      method_option :field, :type => :string
      method_option :selector, :type => :string
      method_option :explain, :type => :boolean, :default => false
      method_option :service, :type => :string, :default => 'EmissionEstimateService'
      def trend
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        Billable::Trend.new(service.billables, options.slice(:field).merge(:selector => selector)).to_csv($stdout)
      end
      
      private
      
      def service
        Billing.const_get(options[:service]).instance
      end
      
      def selector
        hsh = ::ActiveSupport::JSON.decode(options[:selector])
        raise ::ArgumentError, "Selector must be a JSON hash like { foo: 'bar' }" unless hsh.is_a?(::Hash)
        hsh.inject({}) do |memo, (k, v)|
          memo[k] = v.is_a?(::Date) ? v.to_time : v # mongo can't handle dates
          memo
        end
      end

#{'params.airline':'AA','params.date':'2009-04-30','params.timeframe':'2009-01-01/2010-01-01','emitter':'Flight','params.origin_airport':'STL','params.destination_airport':'LAX','key':'sdaiosjaoisdjaoisdjaojsd','params.segments_per_trip':'1','params.trips':'1','params.aircraft':'M83'}

      def flatten_selector(selector)
        selector.inject({}) do |memo, (k, v)|
          if v.is_a?(::Hash)
            v.each do |k1, v1|
              if v1.is_a?(::Hash) # maybe i could rewrite this to be recursive... as it is, 2 levels seems enough
                v1.each do |k11, v11|
                  memo["#{k}.#{k1}.#{k11}"] = v11
                end
              else
                memo["#{k}.#{k1}"] = v1
              end
            end
          else
            memo[k] = v
          end
          memo
        end
      end
    end
  end
end

BrighterPlanet::Billing::CLI.start
