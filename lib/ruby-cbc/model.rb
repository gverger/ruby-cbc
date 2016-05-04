module Cbc
  INF = 1.0 / 0.0 # Useful for ranges

  def self.add_all(variables)
    to_add = variables.map do |variable|
      case variable
      when Numeric, Ilp::Term
        variable
      when Ilp::Var
        Ilp::Term.new(variable)
      else
        raise "Not a variable, a term or a numeric"
      end
    end
    Ilp::TermArray.new(to_add)
  end

  class Model
    attr_accessor :vars, :constraints, :objective, :name

    def initialize(name: "ILP Problem")
      @vars = []
      @constraints = []
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
      var(Ilp::Var::BINARY_KIND, 0..1, name)
    end

    def bin_var_array(length, names: nil)
      array_var(length, Ilp::Var::BINARY_KIND, 0..1, names)
    end

    def cont_var(range = nil, name: nil)
      var(Ilp::Var::CONTINUOUS_KIND, range, name)
    end

    def cont_var_array(length, range = nil, names: nil)
      array_var(length, Ilp::Var::CONTINUOUS_KIND, range, names)
    end

    def enforce(*constraints)
      constraints.each do |constraint|
        if constraint.instance_of? Ilp::Constraint
          self.constraints << constraint
        elsif constraint.instance_of? Array
          self.constraints.concat constraint
        elsif constraint.instance_of? Hash
          to_add = constraint.map do |name, cons|
            cons.tap { |c| c.function_name = name.to_s }
          end
          self.constraints.concat to_add
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
      Cbc::Problem.from_model(self)
    end

    def to_s
      str = if objective
              "#{objective}\n"
            else
              "Maximize\n  0 #{vars.first}\n"
            end

      str << "\nSubject To\n"
      constraints.each do |cons|
        str << "  #{cons}\n"
      end
      bounded_vars = vars.select { |v| v.kind != Ilp::Var::BINARY_KIND }
      unless bounded_vars.empty?
        str << "\nBounds\n"
        bounded_vars.each do |v|
          str << "  #{lb_to_s(v.lower_bound)} <= #{v} <= #{ub_to_s(v.upper_bound)}\n"
        end
      end

      int_vars = vars.select { |v| v.kind == Ilp::Var::INTEGER_KIND }
      unless int_vars.empty?
        str << "\nGenerals\n"
        int_vars.each { |v| str << "  #{v}\n" }
      end

      bin_vars = vars.select { |v| v.kind == Ilp::Var::BINARY_KIND }
      unless bin_vars.empty?
        str << "\nBinaries\n"
        bin_vars.each { |v| str << "  #{v}\n" }
      end
      str << "\nEnd\n"

      str
    end

    private

    def array_var(length, kind, range, names)
      ar = Array.new(length) { var(kind, range, nil) }
      ar.zip(names).each { |var, name| var.name = name } unless names.nil?
      ar
    end

    def var(kind, range, name)
      v = if range.nil?
            Ilp::Var.new(kind: kind, name: name)
          else
            Ilp::Var.new(kind: kind, name: name, lower_bound: range.min, upper_bound: range.max)
          end
      @vars << v
      v
    end

    def lb_to_s(lb)
      return "-inf" if lb.nil? || lb == -Cbc::INF
      return "+inf" if lb == Cbc::INF
      lb.to_s
    end

    def ub_to_s(ub)
      return "+inf" if ub.nil? || ub == Cbc::INF
      return "-inf" if ub == -Cbc::INF
      ub.to_s
    end
  end
end
