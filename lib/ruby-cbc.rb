require "ruby-cbc/version"
require "cbc-wrapper"

module Cbc
end

files = %w(
  conflict_solver
  model
  problem
  version
  ilp/constant
  ilp/constraint
  ilp/objective
  ilp/term
  ilp/term_array
  ilp/var
  utils/compressed_row_storage
)

files.each do |file|
  require File.expand_path("../ruby-cbc/#{file}", __FILE__)
end
