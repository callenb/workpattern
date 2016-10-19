# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "workpattern/version"

Gem::Specification.new do |s|
  s.name        = "workpattern"
  s.version     = Workpattern::VERSION
  s.authors     = ["Barrie Callender"]
  s.email       = ["barrie@callenb.org"]
  s.homepage    = "http://github.com/callenb/workpattern"
  s.summary     = %q{Calculates dates and durations whilst taking into account working and non-working periods down to a minute}
  s.description = %q{Calculates dates and durations whilst taking into account working and non-working times down to a minute.  Business working time with holidays are a breeze.}
  s.license     = 'MIT'

  s.required_ruby_version = ">= 1.9.3"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  s.add_runtime_dependency 'tzinfo'
  s.add_development_dependency('rake', ['~> 0.9.2'])
  s.add_development_dependency('minitest', ['~> 5.4.3'])
end

