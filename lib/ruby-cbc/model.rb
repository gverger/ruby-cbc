require "set"

module Cbc

  INF = 1.0 / 0.0 # Useful for ranges

  class Model


    attr_accessor :vars, :constraints, :objective

    def initialize
      @vars = Set.new
      @constraints = Set.new
      @objective = nil
    end

    def int_var(range = nil, name: nil)
      var(Ilp::Var::INTEGER_KIND, range, name)
    end

    def int_var_array(length, range = nil, names: nil)
      array_var(length, Ilp::Var::INTEGER_KIND, range, names)
    end

    def bin_var(name: nil)
      var(Ilp::Var::BINARY_KIND, nil, name)
    end

    def bin_var_array(length, names: nil)
      array_var(length, Ilp::Var::BINARY_KIND, range, names)
    end

    def cont_var(range = nil, name: nil)
      var(Ilp::Var::CONTINUOUS_KIND, range, name)
    end

    def cont_var_array(length, range = nil, name: nil)
      array_var(length, Ilp::Var::CONTINUOUS_KIND, range, names)
    end

    def enforce(constraint)
      constraints << constraint
    end

    def minimize(expression)
      @objective = Ilp::Objective.new(expression, Ilp::Objective::MINIMIZE)
      self
    end

    def maximize(expression)
      @objective = Ilp::Objective.new(expression, Ilp::Objective::MAXIMIZE)
      self
    end

    def to_problem
      Cbc::Problem.new(self)
    end

  private
    def array_var(length, kind, range, names)
      ar = Array.new(length) { var(kind, range, nil) }
      ar.zip(names).map{ |var, name| var.name = name } unless names.nil?
      ar
    end

    def var(kind, range, name)
      if range.nil?
        v = Ilp::Var.new(kind: kind, name: name)
        @vars << v
        return v
      end
      v = Ilp::Var.new(kind: kind, name: name, lower_bound: range.min, upper_bound: range.max)
      @vars << v
      v
    end
  end
end
