# Installation

## Gemfile

Gem is not in rubygems.org

    gem 'brighter_planet_billing', :git => 'git://github.com/brighterplanet/billing.git'

# Usage

## Setup

Define mongodb connection settings

    BrighterPlanet.billing.config.mongo_host='billinghost.com'
    BrighterPlanet.billing.config.mongo_arbiter_host='abattoir.billinghost.com'
    BrighterPlanet.billing.config.mongo_username='user'
    BrighterPlanet.billing.config.mongo_password='password'
    BrighterPlanet.billing.config.mongo_database='db'

Optionally, in a rails app, create the CacheEntry table for [insert_reason]

    BrighterPlanet.billing.setup

## Billing stats

### Total number of CM1 queries

    BrighterPlanet.billing.cm1.queries.count

### CM1 result statistics

    flight_sample = BrighterPlanet.billing.cm1.queries.sample(:selector => {:emitter => 'Flight', :key => 'ABC123'})
    stats = flight_sample.stats('impact.carbon', :mean, :sd)

### CM1 usage statistics for a key

    usage = BrighterPlanet.billing.cm1.queries.
      usage(:start_at => Time.parse('2011-04-01'), :end_at => Time.parse('2011-05-01'),
            :period => 5.days, :selector => { :key => 'ABC123' })
    puts usage.to_a.inspect

## Billing operations

### Bill a certified CM1 query

    BrighterPlanet.billing.cm1.bill do |query|
      query.certified = true
      query.key = 'ABC123'
      query.timeframe = Timeframe.this_year
      query.input = { :my => 'params' }
      query.url = 'http://query.bp.com/automobiles.json'
      query.emitter = 'Automobile'
      query.remote_ip = '127.0.0.1'
      query.referer = 'http://example.com/quux'
      query.impact = { 'carbon' => 12345 }

      execution_id = query.execution_id
    end
    
    puts "Executed query with #{execution_id}"

# Mongo stats command

mon-get-stats PageViewCount -n "MyService" -s "Sum,Maximum,Minimum,Average,SampleCount" --start-time 2011-03-14T12:00:00.000Z --end-time 2011-03-14T12:01:00.000Z --headers
as found on
http://docs.amazonwebservices.com/AmazonCloudWatch/latest/DeveloperGuide/
(http://docs.amazonwebservices.com/AmazonCloudWatch/latest/DeveloperGuide/publishingMetrics.html)
