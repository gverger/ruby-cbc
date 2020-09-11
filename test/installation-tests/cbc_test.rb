# frozen_string_literal: true

require 'ruby-cbc'

m = Cbc::Model.new
x1, x2, x3 = m.int_var_array(3, 0..Cbc::INF)

m.maximize(10 * x1 + 6 * x2 + 4 * x3)

m.enforce(x1 + x2 + x3 <= 100)
m.enforce(10 * x1 + 4 * x2 + 5 * x3 <= 600)
m.enforce(2 * x1 + 2 * x2 + 6 * x3 <= 300)

p = m.to_problem

p.solve

if p.proven_infeasible?
  puts 'Infeasible problem!'
  exit 1
end

unless p.proven_optimal?
  puts 'Not proven optimal!'
  exit 1
end

if p.objective_value != 732
  puts "Objective value should be 732, but it is #{p.objective_value}"
  exit 1
end
