require "cbc/version"

module Cbc
end

files = %w(
cbc_wrapper
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
  require File.expand_path("../cbc/#{file}", __FILE__)
end
