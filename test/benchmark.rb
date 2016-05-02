$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'ruby-cbc'
require "benchmark/ips"

module Cbc
  class Benchmark
    NB_VARS = 100_000
    NB_CONSTRAINTS = 10000
    NB_VARS_PER_CONSTRAINT = 1..1000

    def self.to_problem(model)
      model.to_problem
    end

    def self.run
      puts "Running"

      model = Cbc::Model.new
      model.int_var_array(NB_VARS)
      model.constraints = NB_CONSTRAINTS.times.map do
        nb_vars = rand(NB_VARS_PER_CONSTRAINT)
        terms = model.vars.to_a.sample(nb_vars).map { |v| v * rand(-10..10) }
        Cbc.add_all(terms) <= 0
      end
      nb_vars = rand(NB_VARS_PER_CONSTRAINT)
      terms = model.vars.to_a.sample(nb_vars).map { |v| v * rand(-10..10) }
      model.maximize(Cbc.add_all(terms))

      ::Benchmark.ips do |x|
        x.report { model.to_problem }
      end
    end
  end
end

Cbc::Benchmark.run
