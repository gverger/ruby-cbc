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

# RSpec::Core::RakeTask.new(:spec)
#
# spec = Gem::Specification.load('ruby-cbc.gemspec')
# Rake::ExtensionTask.new('ruby-cbc', spec) do |ext|
#   ext.lib_dir = 'lib/ruby-cbc'
#   ext.tmp_dir = "tmp"
#   ext.name = 'cbc_wrapper'
# end

SHARED_LIBRARY_EXTENSION = RUBY_PLATFORM.include?("darwin") ? 'bundle' : 'so'
EXTENSION = 'lib/ruby-cbc/cbc_wrapper.'+SHARED_LIBRARY_EXTENSION

desc "Use extconf.rb and make to build the extension."
task :build_extension => EXTENSION

file EXTENSION => 'ext/ruby-cbc/cbc_wrap.c' do
  puts "start"
  in_dir('ext/ruby-cbc') do
    system("ruby extconf.rb")
    system("make")
  end
end

CLEAN.include('ext/ruby-cbc/Makefile', 'ext/ruby-cbc/conftest.dSYM', 'ext/ruby-cbc/mkmf.log', 'ext/ruby-cbc/cbc_wrap.o')

CLOBBER.include('ext/ruby-cbc/cbc_wrap.c', 'ruby-cbc.gemspec')

task :default => [:build_extension, :spec]
