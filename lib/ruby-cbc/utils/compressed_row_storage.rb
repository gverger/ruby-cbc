module Cbc
  module Util
    class CompressedRowStorage
      attr_accessor :model, :variable_index, :row_ptr, :col_idx, :values

      def self.from_model(model)
        new.tap do |crs|
          crs.model = model
          crs.make_variable_index
          crs.fill_matrix
        end
      end

      def nb_constraints
        row_ptr.size - 1
      end

      def make_variable_index
        indexes = @model.vars.size.times.to_a
        @variable_index = model.vars.zip(indexes).to_h
      end

      def init_matrix
        nb_values = model.constraints.map { |c| c.terms.size }.inject(:+) || 0
        @row_ptr = Array.new(model.constraints.size)
        @col_idx = Array.new(nb_values)
        @values = Array.new(nb_values)
      end

      def fill_matrix
        init_matrix
        nb_cols = 0
        c_idx = 0
        while c_idx < @model.constraints.size
          constraint = @model.constraints[c_idx]
          @row_ptr[c_idx] = nb_cols
          nb_insert = constraint.terms.size
          @col_idx[nb_cols, nb_insert] = constraint.terms.map { |term| variable_index[term.var] }
          @values[nb_cols, nb_insert] = constraint.terms.map(&:mult)
          nb_cols += nb_insert
          c_idx += 1
        end
        @row_ptr << @col_idx.size
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

      def present_var_indexes
        present = Array.new(@variable_index.size, false)
        @col_idx.each { |col_idx| present[col_idx] = true }
        present
      end

      def new_indexes
        present = present_var_indexes
        return nil if present.all?
        new_idx = Array.new(@variable_index.size, -1)
        current_index = 0
        new_idx.size.times.each do |idx|
          next unless present[idx]
          new_idx[idx] = current_index
          current_index += 1
        end
        new_idx
      end

      def change_indexes(new_idx)
        new_variable_index = {}
        @variable_index.each do |v, i|
          new_variable_index[v] = new_idx[i] if new_idx[i] != -1
        end
        @variable_index = new_variable_index
      end

      def delete_missing_vars
        new_idx = new_indexes
        return if new_idx.nil?

        change_indexes(new_idx)

        @col_idx.map! { |i| new_idx[i] }
        @model.vars = Array.new(@variable_index.size)
        @variable_index.each { |var, i| @model.vars[i] = var }
      end

      def move_constraint_to_start(range_idxs)
        # Move in the model
        constraints = model.constraints[range_idxs]
        @model.constraints = @model.constraints.clone
        @model.constraints[constraints.size, range_idxs.max] = model.constraints[0, range_idxs.min]
        @model.constraints[0, constraints.size] = constraints

        # Move in the matrix
        constraint_start_idx = @row_ptr[range_idxs.min]
        nb_vars = @row_ptr[range_idxs.max + 1] - constraint_start_idx
        offset = @row_ptr[range_idxs.min]
        new_begin = @row_ptr[range_idxs].map! { |idx| idx - offset }
        ((range_idxs.size)..(range_idxs.max)).reverse_each do |idx|
          @row_ptr[idx] = @row_ptr[idx - range_idxs.size] + nb_vars
        end
        @row_ptr[0, range_idxs.size] = new_begin
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
end
