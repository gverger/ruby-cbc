module Util
  class CompressedRowStorage

    attr_accessor :model, :variable_index, :row_ptr, :col_idx, :values

    def self.from_model(model)
      new.tap do |crs|
        crs.model = model
        crs.variable_index = {}
        idx = 0
        while idx < model.vars.size do
          v = model.vars[idx]
          crs.variable_index[v] = idx
          idx += 1
        end
        crs.fill_matrix
      end
    end

    def nb_constraints
      row_ptr.count - 1
    end

    def fill_matrix
      nb_values = model.constraints.map { |c| c.terms.count }.inject(:+) || 0
      @row_ptr = Array.new(model.constraints.count)
      @col_idx = Array.new(nb_values)
      @values = Array.new(nb_values)

      nb_cols = 0
      c_idx = 0
      while c_idx < @model.constraints.size do
        constraint = @model.constraints[c_idx]
        @row_ptr[c_idx] = nb_cols
        nb_insert = constraint.terms.count
        @col_idx[nb_cols, nb_insert] = constraint.terms.map { |term| variable_index[term.var] }
        @values[nb_cols, nb_insert] = constraint.terms.map { |term| term.mult }
        nb_cols += nb_insert
        c_idx += 1
      end
      @row_ptr << @col_idx.count
    end

    def restrict_to_n_constraints(nb_constraints)
      length_of_values = @row_ptr[nb_constraints]
      CompressedRowStorage.new.tap do |crs|
        crs.model = @model.clone
        crs.variable_index = @variable_index
        crs.row_ptr = @row_ptr[0, nb_constraints + 1]
        crs.col_idx = @col_idx[0, length_of_values]
        crs.values = @values[0, length_of_values]
        crs.delete_missing_vars
      end
    end

    def present_var_indices
      is_present = Array.new(@variable_index.count, false)
      @col_idx.each do |col_idx|
        is_present[col_idx] = true
      end
      is_present
    end

    def delete_missing_vars
      at_least_one_missing = false
      here = present_var_indices
      new_idx = Array.new(@variable_index.count, -1)
      idx = 0
      current_index = 0
      while idx < new_idx.size do
        if here[idx]
          new_idx[idx] = current_index
          current_index += 1
        else
          at_least_one_missing = true
        end
        idx += 1
      end

      return unless at_least_one_missing

      new_variable_index = {}
      @variable_index.each do |v, i|
        new_variable_index[v] = new_idx[i] if new_idx[i] != -1
      end
      @variable_index = new_variable_index
      @col_idx.map! { |idx| new_idx[idx] }
      @model.vars = Array.new(@variable_index.size)
      @variable_index.each do |var, idx|
        @model.vars[idx] = var
      end
    end

    def move_constraint_to_start(range_idxs)
      # Move in the model
      constraints = model.constraints[range_idxs]
      @model.constraints = @model.constraints.clone
      @model.constraints[constraints.count, range_idxs.max] = model.constraints[0, range_idxs.min]
      @model.constraints[0, constraints.count] = constraints

      # Move in the matrix
      constraint_start_idx = @row_ptr[range_idxs.min]
      nb_vars = @row_ptr[range_idxs.max + 1] - constraint_start_idx
      offset= @row_ptr[range_idxs.min]
      new_begin = @row_ptr[range_idxs].map! { |idx| idx - offset }
      ((range_idxs.count)..(range_idxs.max)).reverse_each do |idx|
        @row_ptr[idx] = @row_ptr[idx - range_idxs.count] + nb_vars
      end
      @row_ptr[0, range_idxs.count] = new_begin
      move_block_to_start(@col_idx, constraint_start_idx, nb_vars)
      move_block_to_start(@values, constraint_start_idx, nb_vars)
    end

    def move_block_to_start(array, block_start_idx, nb_values)
      to_move = array[block_start_idx, nb_values]
      array[nb_values, block_start_idx] = array[0, block_start_idx]
      array[0, nb_values] = to_move
    end

  end
end
