module Cbc
  class NativeProblem
    def self.from_problem(problem)
      new(problem.crs, problem.variable_index, problem.model, problem.continuous)
    end

    attr_reader :crs, :variable_index, :continuous, :model
    def initialize(crs, variable_index, model, continuous)
      @crs = crs
      @variable_index = variable_index
      @continuous = continuous
      @model = model
      prepare_problem
    end

    def prepare_problem
      @int_arrays = []
      @double_arrays = []

      ccs = Util::CompressedColumnStorage.from_compressed_row_storage(@crs)
      objective = Array.new(ccs.nb_vars, 0)
      if model.objective
        model.objective.terms.each do |term|
          objective[@variable_index[term.var]] = term.mult
        end
      end

      @cbc_model = Cbc_wrapper.Cbc_newModel
      Cbc_wrapper.Cbc_loadProblem(@cbc_model,
                                  ccs.nb_vars,
                                  @crs.nb_constraints,
                                  native_int_array(ccs.col_ptr),
                                  native_int_array(ccs.row_idx),
                                  native_double_array(ccs.values),
                                  nil,
                                  nil,
                                  native_double_array(objective),
                                  nil,
                                  nil)

      # Segmentation errors when setting name
      # Cbc_wrapper.Cbc_setProblemName(@cbc_model, model.name) if model.name

      if model.objective
        obj_sense = model.objective.objective_function == Ilp::Objective::MINIMIZE ? 1 : -1
        Cbc_wrapper.Cbc_setObjSense(@cbc_model, obj_sense)
      end

      idx = 0
      while idx < @crs.nb_constraints
        contraint = @crs.model.constraints[idx]
        set_constraint_bounds(contraint, idx)
        idx += 1
      end
      idx = 0
      while idx < ccs.nb_vars
        v = @crs.model.vars[idx]
        if continuous
          Cbc_wrapper.Cbc_setContinuous(@cbc_model, idx)
        else
          case v.kind
          when Ilp::Var::INTEGER_KIND, Ilp::Var::BINARY_KIND
            Cbc_wrapper.Cbc_setInteger(@cbc_model, idx)
          when Ilp::Var::CONTINUOUS_KIND
            Cbc_wrapper.Cbc_setContinuous(@cbc_model, idx)
          end
        end
        Cbc_wrapper.Cbc_setColLower(@cbc_model, idx, v.lower_bound) unless v.lower_bound.nil?
        Cbc_wrapper.Cbc_setColUpper(@cbc_model, idx, v.upper_bound) unless v.upper_bound.nil?
        idx += 1
      end

      ObjectSpace.define_finalizer(self,
                                   self.class.finalizer(@cbc_model, @int_arrays, @double_arrays))

      @default_solve_params = {
        log: 0
      }
    end

    def set_constraint_bounds(contraint, idx)
      case contraint.type
      when Ilp::Constraint::LESS_OR_EQ
        Cbc_wrapper.Cbc_setRowUpper(@cbc_model, idx, contraint.bound)
      when Ilp::Constraint::GREATER_OR_EQ
        Cbc_wrapper.Cbc_setRowLower(@cbc_model, idx, contraint.bound)
      when Ilp::Constraint::EQUALS
        Cbc_wrapper.Cbc_setRowUpper(@cbc_model, idx, contraint.bound)
        Cbc_wrapper.Cbc_setRowLower(@cbc_model, idx, contraint.bound)
      end
    end

    def solve(params = {})
      @default_solve_params.merge(params).each do |name, value|
        Cbc_wrapper.Cbc_setParameter(@cbc_model, name.to_s, value.to_s)
      end
      Cbc_wrapper.Cbc_solve(@cbc_model)
      @solution = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getColSolution(@cbc_model))
      @double_arrays << @solution
      run_status
    end

    def run_status
      RunStatus.new(
        assignments: assignments,
        optimal: proven_optimal?,
        infeasible: proven_infeasible?,
        time_limit_reached: time_limit_reached?,
        solution_limit_reached: solution_limit_reached?,
        objective_value: objective_value,
        best_bound: best_bound
      )
    end

    def proven_optimal?
      Cbc_wrapper.Cbc_isProvenOptimal(@cbc_model) == 1
    end

    def proven_infeasible?
      Cbc_wrapper.Cbc_isProvenInfeasible(@cbc_model) == 1
    end

    def time_limit_reached?
      Cbc_wrapper.Cbc_isSecondsLimitReached(@cbc_model) == 1
    end

    def solution_limit_reached?
      Cbc_wrapper.Cbc_isSolutionLimitReached(@cbc_model) == 1
    end

    def objective_value
      Cbc_wrapper.Cbc_getObjValue(@cbc_model)
    end

    # Returns the best know bound so far
    def best_bound
      Cbc_wrapper.Cbc_getBestPossibleObjValue(@cbc_model)
    end

    def assignments
      @variable_index.map do |var, index|
        value = @solution[index]
        value = value.round unless var.continuous?
        value
      end
    end

    def write
      Cbc_wrapper.Cbc_writeMps(@cbc_model, "test")
    end

    def self.finalizer(cbc_model, int_arrays, double_arrays)
      proc do
        Cbc_wrapper.Cbc_deleteModel(cbc_model)
        int_arrays.each { |ar| Cbc_wrapper.delete_intArray(ar) }
        double_arrays.each { |ar| Cbc_wrapper.delete_doubleArray(ar) }
      end
    end

    private

    def native_int_array(array)
      c_array = Cbc_wrapper::IntArray.new(array.size)
      idx = 0
      while idx < array.size
        c_array[idx] = array[idx]
        idx += 1
      end
      @int_arrays << c_array
      c_array
    end

    def native_double_array(array)
      c_array = Cbc_wrapper::DoubleArray.new(array.size)
      idx = 0
      while idx < array.size
        c_array[idx] = array[idx]
        idx += 1
      end
      @double_arrays << c_array
      c_array
    end
  end
end
