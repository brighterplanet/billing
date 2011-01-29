# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "brighter_planet_billing/version"

Gem::Specification.new do |s|
  s.name        = "brighter_planet_billing"
  s.version     = ::BrighterPlanet::Billing::VERSION
  s.platform    = Gem::Platform::RUBY
  s.authors     = ["Seamus Abshere"]
  s.email       = ["seamus@abshere.net"]
  s.homepage    = ""
  s.summary     = %q{Checks usage for our services}
  s.description = %q{Sends and receives usage information for carbon middleware}

  s.rubyforge_project = "brighter_planet_billing"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
  
  s.add_development_dependency 'test-unit'
  if RUBY_VERSION >= '1.9'
    s.add_development_dependency 'ruby-debug19'
  else
    s.add_development_dependency 'ruby-debug'
  end
  s.add_development_dependency 'sqlite3-ruby'
  s.add_development_dependency 'leap'
  s.add_dependency 'i18n'
  s.add_dependency 'hoptoad_notifier', '~> 2.3.0'
  s.add_dependency 'builder'
  s.add_dependency 'mongo'
  s.add_dependency 'bson'
  s.add_dependency 'bson_ext'
  s.add_dependency 'activesupport', '>=2.3'
  s.add_dependency 'activerecord', '>=2.3'
end
