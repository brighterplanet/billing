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

SAMPLE
#{__FILE__} sample --fields=emitter started_at params emission --digest params --selector=emitter:Flight key:${TRIPCARBON_KEY}

TREND
#{__FILE__} trend --field=emission --selector=emitter:Flight key:${TRIPCARBON_KEY}
}
# TOP
# #{__FILE__} top --limit=5 --field=params --selector=emitter:Flight key:${TRIPCARBON_KEY}
# 
# TOP (with query explain, which can be used to optimize your query/figure out what indexes are needed)
# #{__FILE__} top --explain=true --limit=5 --field=params --selector=emitter:Flight key:${TRIPCARBON_KEY}
      end
      
      desc "sample", "get a representative sample based on a query"
      method_option :limit, :type => :numeric, :default => Billable::Sample::LIMIT
      method_option :digest, :type => :array, :description => "Include a digest (hashcode) for these columns to make it easy to sort. Useful for columns that contain hashes."
      method_option :selector, :type => :string #:hash
      method_option :fields, :type => :array
      method_option :explain, :type => :boolean, :default => false
      def sample(service_name = 'EmissionEstimateService')
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        service = Billing.const_get(service_name).instance
        selector = ::ActiveSupport::JSON.decode(options[:selector])
        if ary = options[:fields] and ary.first.include?(',')
          $stderr.puts "WARNING: commas seen in field definition, separate with spaces instead"
        end
        Billable::Sample.new(service.billables, options.slice(:limit).merge(:selector => selector)).to_csv($stdout, options.slice(:fields, :digest))
      end
      
      desc "trend", "get a daily average and standard deviation of a certain field"
      method_option :field, :type => :string
      method_option :selector, :type => :hash
      method_option :explain, :type => :boolean, :default => false
      def trend(service_name = 'EmissionEstimateService')
        options = self.options.dup
        ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
        service = Billing.const_get(service_name).instance
        Billable::Trend.new(service.billables, options.slice(:selector, :field)).to_csv($stdout)
      end
      
      # desc "top", "get the top values of a certain field"
      # method_option :limit, :type => :numeric, :default => 5
      # method_option :field, :type => :string
      # method_option :selector, :type => :hash
      # method_option :explain, :type => :boolean, :default => false
      # def top(service_name = 'EmissionEstimateService')
      #   options = self.options.dup
      #   ::ENV['BRIGHTER_PLANET_BILLING_EXPLAIN'] = 'true' if options.delete(:explain) == true
      #   service = Billing.const_get(service_name).instance
      #   Billable::Top.new(service.billables, options.slice(:selector, :field)).to_csv($stdout)
      # end
    end
  end
end

BrighterPlanet::Billing::CLI.start
