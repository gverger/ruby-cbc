module Cbc
  class Problem

    attr_reader :model, :variable_index, :crs

    CRS = Struct.new(:row_start_idx, :col_idx, :values) do
      def restrict_to_n_constraints(nb_constraints)
        length_of_values = row_start_idx[nb_constraints]
        CRS.new(row_start_idx[0, nb_constraints + 1],
                col_idx[0, length_of_values],
                values[0, length_of_values])
      end

      def merge!(crs)
        offset = row_start_idx[-1]
        row_start_idx.concat crs.row_start_idx[1..-1].map! { |idx| idx + offset }
        col_idx.concat crs.col_idx
        values.concat crs.values
      end

    end

    CCS = Struct.new(:col_start_idx, :row_idx, :values)

    def self.to_compressed_row_storage(model, variable_index)
      nb_values = model.constraints.map { |c| c.terms.count }.inject(:+) || 0
      crs = CRS.new(Array.new(model.constraints.count), Array.new(nb_values), Array.new(nb_values))
      nb_cols = 0
      model.constraints.each_with_index do |constraint, c_idx|
        crs.row_start_idx[c_idx] = nb_cols
        nb_insert = constraint.terms.count
        crs.col_idx[nb_cols, nb_insert] = constraint.terms.map { |term| variable_index[term.var] }
        crs.values[nb_cols, nb_insert] = constraint.terms.map { |term| term.mult }
        nb_cols += nb_insert
      end
      crs.row_start_idx << crs.col_idx.count
      crs
    end

    def self.crs_to_ccs(crs, nb_constraints = nil, additional_crs = nil)
      nb_per_column = Array.new(crs.col_idx.max.to_i + 1, 0)

      crs = crs.restrict_to_n_constraints(nb_constraints) unless nb_constraints.nil?
      crs.merge!(additional_crs) unless additional_crs.nil?

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

    def initialize(model, continuous: false, sub_problem_of: nil, nb_constraints: nil, additional_constraints: nil)
      @int_arrays = []
      @double_arrays = []
      @model = model

      if sub_problem_of.nil?
        @variable_index = {}
        model.vars.each_with_index do |v, idx|
          @variable_index[v] = idx
        end

        @crs = self.class.to_compressed_row_storage(model, @variable_index)
      else
        @variable_index = sub_problem_of.variable_index
        @crs = sub_problem_of.crs
      end


      additional_crs = nil
      unless additional_constraints.nil?
        m = Model.new
        m.vars = model.vars
        m.constraints = additional_constraints
        additional_crs = self.class.to_compressed_row_storage(m, @variable_index)
      end
      ccs = self.class.crs_to_ccs(@crs, nb_constraints, additional_crs)

      objective = Array.new(model.vars.count, 0)
      if model.objective
        model.objective.terms.each do |term|
          objective[@variable_index[term.var]] = term.mult
        end
      end

      @cbc_model = Cbc_wrapper.Cbc_newModel
      Cbc_wrapper.Cbc_loadProblem(@cbc_model, model.vars.count, model.constraints.count,
                                  to_int_array(ccs.col_start_idx), to_int_array(ccs.row_idx),
                                  to_double_array(ccs.values), nil, nil, to_double_array(objective),
                                  nil, nil)


      # Segmentation errors when setting name
      # Cbc_wrapper.Cbc_setProblemName(@cbc_model, model.name) if model.name

      if model.objective
        obj_sense = model.objective.objective_function == Ilp::Objective::MINIMIZE ? 1 : -1
        Cbc_wrapper.Cbc_setObjSense(@cbc_model, obj_sense)
      end

      max_nb_constraints = nb_constraints
      max_nb_constraints ||= model.constraints.count

      model.constraints.each_with_index do |c, idx|
        break if idx >= max_nb_constraints
        set_constraint_bounds(c, idx)
      end
      unless additional_constraints.nil?
        additional_constraints.each_with_index do |c, idx|
          set_constraint_bounds(c, max_nb_constraints + idx)
        end
      end
      model.vars.each_with_index do |v, idx|
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
