module Cbc
  class Problem

    attr_accessor :model, :variable_index, :crs

    def self.from_model(model, continuous: false)
      crs = Util::CompressedRowStorage.from_model(model)
      from_compressed_row_storage(crs, continuous: continuous)
    end

    def self.from_compressed_row_storage(crs, continuous: false)
      new.tap do |p|
        p.model = crs.model
        p.variable_index = crs.variable_index
        p.crs = crs
        p.create_cbc_problem(continuous: continuous)
      end
    end

    CCS = Struct.new(:col_start_idx, :row_idx, :values) do
      def nb_vars
        col_start_idx.count - 1
      end
    end

    def self.crs_to_ccs(crs)
      nb_per_column = Array.new(crs.col_idx.max.to_i + 1, 0)
      nb_values = crs.values.count

      crs.col_idx.each { |col_idx| nb_per_column[col_idx] += 1 }

      ccs = CCS.new(Array.new(nb_per_column.count + 1), Array.new(nb_values), Array.new(nb_values))
      ccs.col_start_idx[0] = 0
      nb_per_column.each_with_index do |nb, idx|
        ccs.col_start_idx[idx + 1] = ccs.col_start_idx[idx] + nb
      end

      cols_idx = ccs.col_start_idx.clone
      crs.row_start_idx.each_cons(2).each_with_index do |start_idxs, row_idx|
        from = start_idxs.first
        to = start_idxs.last - 1
        (from..to).each do |idx|
          col_idx = crs.col_idx[idx]
          ccs_col_idx = cols_idx[col_idx]
          cols_idx[col_idx] += 1
          ccs.row_idx[ccs_col_idx] = row_idx
          ccs.values[ccs_col_idx] = crs.values[idx]
        end
      end
      ccs
    end

    def init_attributes
      @int_arrays = []
      @double_arrays = []
    end

    def create_cbc_problem(continuous: false)
      @int_arrays = []
      @double_arrays = []

      ccs = self.class.crs_to_ccs(@crs)
      objective = Array.new(ccs.nb_vars, 0)
      if model.objective
        model.objective.terms.each do |term|
          objective[@variable_index[term.var]] = term.mult
        end
      end

      @cbc_model = Cbc_wrapper.Cbc_newModel
      Cbc_wrapper.Cbc_loadProblem(
        @cbc_model, ccs.nb_vars, @crs.nb_constraints,
        to_int_array(ccs.col_start_idx), to_int_array(ccs.row_idx),
        to_double_array(ccs.values), nil, nil, to_double_array(objective),
        nil, nil)


      # Segmentation errors when setting name
      # Cbc_wrapper.Cbc_setProblemName(@cbc_model, model.name) if model.name

      if model.objective
        obj_sense = model.objective.objective_function == Ilp::Objective::MINIMIZE ? 1 : -1
        Cbc_wrapper.Cbc_setObjSense(@cbc_model, obj_sense)
      end

      model.constraints.each_with_index do |c, idx|
        break if idx >= @crs.nb_constraints
        set_constraint_bounds(c, idx)
      end
      model.vars.each_with_index do |v, idx|
        break if idx >= ccs.nb_vars
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
      end

      ObjectSpace.define_finalizer(self, self.class.finalizer(@cbc_model, @int_arrays, @double_arrays))

      @default_solve_params = {
        log: 0,
      }


    end

    def set_constraint_bounds(c, idx)
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

    def solve(params = {})
      @default_solve_params.merge(params).each do |name, value|
        Cbc_wrapper.Cbc_setParameter(@cbc_model, name.to_s, value.to_s)
      end
      Cbc_wrapper.Cbc_solve(@cbc_model)
      @solution = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getColSolution(@cbc_model))
      @double_arrays << @solution
      @solution
    end

    def value_of(var)
      idx = @variable_index[var]
      return nil if idx.nil?
      if var.kind == Ilp::Var::CONTINUOUS_KIND
        @solution[idx]
      else
        @solution[idx].round
      end
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

    def find_conflict
      @conflict_set ||= ConflictSolver.new(self).find_conflict
    end

    def find_conflict_vars
      @conflict_vars ||= find_conflict.map(&:vars).flatten.uniq
    end

    def self.finalizer(cbc_model, int_arrays, double_arrays)
      proc do
        Cbc_wrapper.Cbc_deleteModel(cbc_model)
        int_arrays.each { |ar| Cbc_wrapper.delete_intArray(ar) }
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

    def to_double_array(array)
      c_array = Cbc_wrapper::DoubleArray.new(array.count)
      array.each_with_index { |value, idx| c_array[idx] = value }
      @double_arrays << c_array
      c_array
    end
  end
end
