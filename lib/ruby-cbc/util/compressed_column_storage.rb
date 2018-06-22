module Cbc
  module Util
    class CompressedColumnStorage
      attr_accessor :col_ptr, :row_idx, :values

      def self.from_compressed_row_storage(crs)
        new(crs)
      end

      def initialize(crs)
        nb_per_column = Array.new(crs.col_idx.max.to_i + 1, 0)
        nb_values = crs.values.size

        crs.col_idx.each { |col_idx| nb_per_column[col_idx] += 1 }

        @col_ptr = Array.new(nb_per_column.size + 1)
        @row_idx = Array.new(nb_values)
        @values = Array.new(nb_values)

        col_ptr[0] = 0
        idx = 0
        while idx < nb_per_column.size
          col_ptr[idx + 1] = col_ptr[idx] + nb_per_column[idx]
          idx += 1
        end

        cols_idx = col_ptr.clone
        current_row_idx = 0
        end_row_idx = crs.row_ptr.size - 1
        while current_row_idx < end_row_idx
          current_idx = crs.row_ptr[current_row_idx]
          last_idx = crs.row_ptr[current_row_idx + 1] - 1
          while current_idx <= last_idx
            col_idx = crs.col_idx[current_idx]
            ccs_col_idx = cols_idx[col_idx]
            cols_idx[col_idx] += 1
            row_idx[ccs_col_idx] = current_row_idx
            values[ccs_col_idx] = crs.values[current_idx]
            current_idx += 1
          end
          current_row_idx += 1
        end
      end

      def nb_vars
        col_ptr.size - 1
      end
    end
  end
end
