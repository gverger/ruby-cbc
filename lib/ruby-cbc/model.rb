require "set"

module Cbc

  INF = 1.0 / 0.0 # Useful for ranges

  class Model


    attr_accessor :vars, :constraints, :objective, :name

    def initialize(name: "ILP Problem")
      @vars = Set.new
      @constraints = Set.new
      @objective = nil
      @name = name
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
      array_var(length, Ilp::Var::BINARY_KIND, nil, names)
    end

    def cont_var(range = nil, name: nil)
      var(Ilp::Var::CONTINUOUS_KIND, range, name)
    end

    def cont_var_array(length, range = nil, name: nil)
      array_var(length, Ilp::Var::CONTINUOUS_KIND, range, names)
    end

    def enforce(*constraints)
      constraints.each do |constraint|
        if constraint.instance_of? Ilp::Constraint
          self.constraints << constraint
        elsif constraint.instance_of? Array
          self.constraints += constraint
        elsif constraint.instance_of? Hash
          constraint.each do |name, c|
            self.constraints << c
            c.name = name.to_s
          end
        else
          puts "Not a constraint: #{constraint}"
        end
      end
    end

    def minimize(expression)
      @objective = Ilp::Objective.new(expression, Ilp::Objective::MINIMIZE) if expression
      self
    end

    def maximize(expression)
      @objective = Ilp::Objective.new(expression, Ilp::Objective::MAXIMIZE) if expression
      self
    end

    def to_problem
      Cbc::Problem.new(self)
    end

    def to_s
      str = ""
      if objective
      str << objective.to_s << "\n"
      else
        str << "Maximize\n  0 #{vars.first.to_s}\n"
      end
      str << "\nSubject To\n"
      constraints.each do |cons|
        str << "  " << cons.to_s << "\n"
      end
      bounded_vars = vars.select{ |v| v.kind != Ilp::Var::BINARY_KIND }
      if bounded_vars.any?
        str << "\nBounds\n"
        bounded_vars.each { |v| str << "  #{lb_to_s(v.lower_bound)} <= #{v} <= #{ub_to_s(v.upper_bound)}\n" }
      end

      int_vars = vars.select{ |v| v.kind == Ilp::Var::INTEGER_KIND }
      if int_vars.any?
        str << "\nGenerals\n"
        int_vars.each { |v| str << "  #{v}\n" }
      end

      bin_vars = vars.select{ |v| v.kind == Ilp::Var::BINARY_KIND }
      if bin_vars.any?
        str << "\nBinaries\n"
        bin_vars.each { |v| str << "  #{v}\n" }
      end
      str << "\nEnd\n"

      str
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

    def lb_to_s(lb)
      return "-inf" if ! lb || lb == -Cbc::INF
      return "+inf" if lb == Cbc::INF
      return "#{lb}"
    end

    def ub_to_s(ub)
      return "+inf" if ! ub || ub == Cbc::INF
      return "-inf" if ub == -Cbc::INF
      return "#{ub}"
    end

  end
end
