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
  s.add_dependency 'i18n'
  s.add_dependency 'aws', '>=2.3.26', '<2.4'
  s.add_dependency 'blockenspiel'
  s.add_dependency 'hoptoad_notifier', '2.3.0'
  s.add_dependency 'builder'
  s.add_dependency 'activesupport', '~>3'
end
