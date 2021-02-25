# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

require_relative "lib/workpattern/version"

Gem::Specification.new do |spec|
  spec.name          = "workpattern"
  spec.version       = Workpattern::VERSION
  spec.authors       = ["Barrie Callender"]
  spec.email         = ["barrie@callenb.org"]

  spec.summary       = "Calculates dates and durations whilst taking into account working and non-working periods down to a minute"
  spec.description   = "Calculates dates and durations whilst taking into account working and non-working times down to a minute.  Business working time with holidays are a breeze."
  spec.homepage      = "http://workpattern.org"
  spec.license       = "MIT"  
  spec.required_ruby_version = Gem::Requirement.new(">= 1.9.3")

  spec.metadata["homepage_url"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/callenb/workpattern"
  spec.metadata["changelog_uri"] = "https://workpattern.org/2021/02/25/changelog.html"

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{\A(?:test|spec|features)/}) }
  end
  spec.require_paths = ["lib"]

  # Uncomment to register a new dependency of your gem
  # spec.add_dependency "example-gem", "~> 1.0"

  # For more information and examples about making a new gem, checkout our
  # guide at: https://bundler.io/guides/creating_gem.html
  spec.add_runtime_dependency 'tzinfo'
  spec.add_runtime_dependency 'sorted_set' if RUBY_VERSION >= "2.4"
  spec.test_files            = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths         = ["lib"]
  
end
