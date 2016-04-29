module Util
  class CompressedRowStorage

    attr_accessor :model, :variable_index, :row_start_idx, :col_idx, :values

    def self.from_model(model)
      new.tap do |crs|
        crs.model = model
        crs.variable_index = {}
        model.vars.each_with_index do |v, idx|
          crs.variable_index[v] = idx
        end
        crs.fill_matrix
      end
    end

    def nb_constraints
      row_start_idx.count - 1
    end

    def fill_matrix
      nb_values = model.constraints.map { |c| c.terms.count }.inject(:+) || 0
      @row_start_idx = Array.new(model.constraints.count)
      @col_idx = Array.new(nb_values)
      @values = Array.new(nb_values)

      nb_cols = 0
      @model.constraints.each_with_index do |constraint, c_idx|
        @row_start_idx[c_idx] = nb_cols
        nb_insert = constraint.terms.count
        @col_idx[nb_cols, nb_insert] = constraint.terms.map { |term| variable_index[term.var] }
        @values[nb_cols, nb_insert] = constraint.terms.map { |term| term.mult }
        nb_cols += nb_insert
      end
      @row_start_idx << @col_idx.count
    end

    def restrict_to_n_constraints(nb_constraints)
      length_of_values = @row_start_idx[nb_constraints]
      CompressedRowStorage.new.tap do |crs|
        crs.model = @model
        crs.variable_index = @variable_index
        crs.row_start_idx = @row_start_idx[0, nb_constraints + 1]
        crs.col_idx = @col_idx[0, length_of_values]
        crs.values = @values[0, length_of_values]
      end
    end

    def move_constraint_to_start(range_idxs)
      # Move in the model
      constraints = model.constraints[range_idxs]
      @model.constraints = @model.constraints.clone
      @model.constraints[constraints.count, range_idxs.max] = model.constraints[0, range_idxs.min]
      @model.constraints[0, constraints.count] = constraints

      # Move in the matrix
      constraint_start_idx = @row_start_idx[range_idxs.min]
      nb_vars = @row_start_idx[range_idxs.max + 1] - constraint_start_idx
      puts "BIZARRE" if nb_vars.zero?
      offset= @row_start_idx[range_idxs.min]
      new_begin = @row_start_idx[range_idxs].map! { |idx| idx - offset }
      ((range_idxs.count)..(range_idxs.max)).reverse_each do |idx|
        @row_start_idx[idx] = @row_start_idx[idx - range_idxs.count] + nb_vars
      end
      @row_start_idx[0, range_idxs.count] = new_begin
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
