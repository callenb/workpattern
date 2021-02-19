# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "workpattern/version"

Gem::Specification.new do |s|
  s.name                  = "workpattern"
  s.version               = Workpattern::VERSION
  s.summary               = "Calculates dates and durations whilst taking into account working and non-working periods down to a minute"
  s.description           = "Calculates dates and durations whilst taking into account working and non-working times down to a minute.  Business working time with holidays are a breeze."
  s.authors               = ["Barrie Callender"]
  s.email                 = ["barrie@callenb.org"]
  s.files                 = `git ls-files`.split("\n")
  s.homepage              = "http://github.com/callenb/workpattern"
  s.required_ruby_version = ">= 1.9.3"
  s.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.require_paths         = ["lib"]
  # specify any dependencies here; for example:
  s.add_runtime_dependency 'tzinfo'
  s.add_runtime_dependency 'sorted_set' if RUBY_VERSION >= "2.4"
#  s.add_runtime_dependency 'sorted_set'
  s.add_development_dependency('rake', ['~> 0.9.2'])
  s.add_development_dependency('minitest', ['~> 5.4.3'])
end
