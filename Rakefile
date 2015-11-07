require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/extensiontask'

RSpec::Core::RakeTask.new(:spec)

task :default => :spec

spec = Gem::Specification.load('ruby-cbc.gemspec')
Rake::ExtensionTask.new('ruby-cbc', spec) do |ext|
  ext.lib_dir = 'lib/ruby-cbc'
  ext.tmp_dir = "/tmp"
  ext.name = 'cbc_wrapper'
end
