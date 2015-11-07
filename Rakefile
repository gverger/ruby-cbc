require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/extensiontask'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

spec = Gem::Specification.load('cbc.gemspec')
Rake::ExtensionTask.new('cbc', spec) do |ext|
  ext.lib_dir = 'lib/cbc'
  ext.tmp_dir = "/tmp"
  ext.name = 'cbc_wrapper'
end
