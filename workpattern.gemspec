# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "workpattern/version"

Gem::Specification.new do |s|
  s.name        = "workpattern"
  s.version     = Workpattern::VERSION
  s.authors     = ["Barrie Callender"]
  s.email       = ["barrie@callenb.org"]
  s.homepage    = ""
  s.summary     = %q{temporal calculations}
  s.description = %q{Workpattern performs date calculations that take into account working and resting periods.}

  s.rubyforge_project = "workpattern"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  # specify any dependencies here; for example:
  # s.add_development_dependency "rspec"
  # s.add_runtime_dependency "rest-client"
  s.add_development_dependency('rake', ['~> 0.9.2'])
end
