require "ruby-cbc/cbc_wrapper"

module Cbc
  class Problem


    def initialize(model)

      @int_arrays = []
      @big_index_arrays = []
      @double_arrays = []

      @variables = {}
      vars = model.vars
      vars_data = {}
      vars.each_with_index do |v, idx|
        @variables[v] = idx
        vars_data[v] = VarData.new(v, idx, [], [])
      end

      model.constraints.each_with_index do |c, idx|
        c.terms.each do |term|
          v_data = vars_data[term.var]
          v_data.constraints << idx
          v_data.coefs << term.mult
        end
      end

      indexes = []
      rows = [] 
      coefs = []

      vars.each_with_index do |v, idx|
        v_data = vars_data[v]
        indexes[idx] = rows.count
        rows += v_data.constraints
        coefs += v_data.coefs
      end

      indexes << rows.count

      objective = Array.new(vars.count, 0)
      unless model.objective.nil?
        model.objective.terms.each do |term|
          objective[vars_data[term.var].col_idx] = term.mult
        end
      end

      @cbc_model = Cbc_wrapper.Cbc_newModel
      Cbc_wrapper.Cbc_loadProblem(@cbc_model, model.vars.count, model.constraints.count,
                                 to_int_array(indexes), to_int_array(rows),
                                 to_double_array(coefs), nil, nil, to_double_array(objective),
                                 nil, nil)

      unless model.objective.nil?
        obj_sense = model.objective.objective_function == Ilp::Objective::MINIMIZE ? 1 : -1
        Cbc_wrapper.Cbc_setObjSense(@cbc_model, obj_sense)
      end

      model.constraints.each_with_index do |c, idx|
        case c.type
        when Ilp::Constraint::LESS_OR_EQ
          Cbc_wrapper.Cbc_setRowUpper(@cbc_model, idx, c.bound)
        when Ilp::Constraint::GREATER_OR_EQ
          Cbc_wrapper.Cbc_setRowLower(@cbc_model, idx, c.bound)
        when Ilp::Constraint::EQUALS
          Cbc_wrapper.Cbc_setRowUpper(@cbc_model, idx, c.bound)
          Cbc_wrapper.Cbc_setRowLower(@cbc_model, idx, c.bound)
        end
      end
      model.vars.each_with_index do |v, idx|
        case v.kind 
        when Ilp::Var::INTEGER_KIND
          Cbc_wrapper.Cbc_setInteger(@cbc_model, idx)
        when Ilp::Var::BINARY_KIND
          Cbc_wrapper.Cbc_setInteger(@cbc_model, idx)
          v.bounds = 0..1
        when Ilp::Var::CONTINUOUS_KIND
          Cbc_wrapper.Cbc_setContinuous(@cbc_model, idx)
        end
        Cbc_wrapper.Cbc_setColLower(@cbc_model, idx, v.lower_bound) unless v.lower_bound.nil?
        Cbc_wrapper.Cbc_setColUpper(@cbc_model, idx, v.upper_bound) unless v.upper_bound.nil?
      end

      ObjectSpace.define_finalizer(self, self.class.finalizer(@cbc_model, @int_arrays, @big_index_arrays, @double_arrays))

      @default_solve_params = {
          log: 0,
        }

    end

    def solve(params = {})
      @default_solve_params.merge(params).each do |name, value|
        Cbc_wrapper.Cbc_setParameter(@cbc_model, name.to_s, value.to_s)
      end
      Cbc_wrapper.Cbc_solve(@cbc_model)
      @solution = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getColSolution(@cbc_model))
    end

    def value_of(var)
      idx = @variables[var]
      return nil if idx.nil?
      @solution[idx]
    end

    def set_time_limit(seconds)
      @default_solve_params[:sec] = seconds
    end

    def proven_optimal?
      Cbc_wrapper.Cbc_isProvenOptimal(@cbc_model) == 1
    end

    def proven_infeasible?
      Cbc_wrapper.Cbc_isProvenInfeasible(@cbc_model) == 1
    end

    def time_limit_reached?
      Cbc_wrapper.Cbc_isSecondsLimitReached(@cbc_model)
    end

    def solution_limit_reached?
      Cbc_wrapper.Cbc_isSolutionLimitReached(@cbc_model)
    end

    def objective_value
      Cbc_wrapper.Cbc_getObjValue(@cbc_model)
    end

    # Returns the best know bound so far
    def best_bound
      Cbc_wrapper.Cbc_getBestPossibleObjValue(@cbc_model)
    end

    def self.finalizer(cbc_model, int_arrays, big_index_arrays, double_arrays)
      proc do
        Cbc_wrapper.Cbc_deleteModel(cbc_model)
        int_arrays.each { |ar| Cbc_wrapper.delete_intArray(ar) }
        big_index_arrays.each { |ar| Cbc_wrapper.delete_bigIndexArray(ar) }
        double_arrays.each { |ar| Cbc_wrapper.delete_doubleArray(ar) }
      end
    end

    def write
      Cbc_wrapper.Cbc_writeMps(@cbc_model, "test")
    end

  private

    def to_int_array(array)
      c_array = Cbc_wrapper::IntArray.new(array.count)
      array.each_with_index { |value, idx| c_array[idx] = value }
      @int_arrays << c_array
      c_array
    end

    def to_big_index_array(array)
      c_array = Cbc_wrapper::BigIndexArray.new(array.count)
      array.each_with_index { |value, idx| c_array[idx] = value }
      @big_index_arrays << c_array
      c_array
    end

    def to_double_array(array)
      c_array = Cbc_wrapper::DoubleArray.new(array.count)
      array.each_with_index { |value, idx| c_array[idx] = value }
      @double_arrays << c_array
      c_array 
    end

    VarData = Struct.new(:variable, :col_idx, :constraints, :coefs)
  end

  
end
