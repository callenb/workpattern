require "bundler/gem_tasks"
require "rake/testtask"

task :default => [:test]

desc "Run basic tests"
Rake::TestTask.new do |test|
  test.libs << "test"
  test.test_files = Dir["test/test_*.rb"]
  test.verbose = true
end

task :console do
  require 'irb'
  require 'irb/completion'
  require 'workpattern' # You know what to do.
  ARGV.clear
  IRB.start
end

