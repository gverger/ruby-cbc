require "bundler/gem_tasks"
require "rspec/core/rake_task"
require 'rake/extensiontask'

def in_dir(path)
  original_dir = Dir.pwd
  Dir.chdir(path)
  yield
ensure
  Dir.chdir(original_dir)
end

RSpec::Core::RakeTask.new(:spec)

spec = Gem::Specification.load('ruby-cbc.gemspec')
Rake::ExtensionTask.new('ruby-cbc', spec) do |ext|
  ext.lib_dir = 'lib/ruby-cbc'
  ext.tmp_dir = "tmp"
  ext.name = 'cbc_wrapper'
end

task :default => [:spec]

task :benchmark do
  ruby "test/benchmark.rb"
end
