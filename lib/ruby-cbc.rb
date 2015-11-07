require "ruby-cbc/version"

module Cbc
end

files = %w(
model
problem
version
ilp/constant
ilp/constraint
ilp/objective
ilp/term
ilp/term_array
ilp/var
)

files.each do |file|
  require File.expand_path("../ruby-cbc/#{file}", __FILE__)
end
