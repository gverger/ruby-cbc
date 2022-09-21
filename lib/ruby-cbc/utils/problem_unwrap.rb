# frozen_string_literal: true

module Cbc
  module Utils
    class ProblemUnwrap
      attr_reader :cbc_model

      def initialize(cbc_model)
        @cbc_model = cbc_model
      end

      def to_model
        m = Model.new(name: problem_name)

        variables(m)
        constraints(m)
        objective(m)
        m
      end

      private

      def variables(model)
        lower_bounds = double_array(Cbc_wrapper.Cbc_getColLower(cbc_model))
        upper_bounds = double_array(Cbc_wrapper.Cbc_getColUpper(cbc_model))

        nb_vars.times do |i|
          range = float_value(lower_bounds[i])..float_value(upper_bounds[i])
          if Cbc_wrapper.Cbc_isInteger(cbc_model, i) == 1
            model.int_var(range, name: var_name(i))
          else
            model.cont_var(range, name: var_name(i))
          end
        end
      end

      def constraints(model)
        lower_bounds = double_array(Cbc_wrapper.Cbc_getRowLower(cbc_model))
        upper_bounds = double_array(Cbc_wrapper.Cbc_getRowUpper(cbc_model))

        nb_elements = Cbc_wrapper.Cbc_getNumElements(cbc_model)
        starts = int_array(Cbc_wrapper.Cbc_getVectorStarts(cbc_model))
        indices = int_array(Cbc_wrapper.Cbc_getIndices(cbc_model))
        elements = double_array(Cbc_wrapper.Cbc_getElements(cbc_model))

        cons_terms = Array.new(nb_cons) { [] }

        var_idx = 0
        while var_idx < nb_vars
          from = starts[var_idx]
          to = var_idx == nb_vars - 1 ? nb_elements : starts[var_idx + 1]

          var = model.vars[var_idx]
          (from...to).each do |i|
            cons_idx = indices[i]
            mult = elements[i]
            cons_terms[cons_idx] << var * mult
          end

          var_idx += 1
        end

        cons_terms.each_with_index do |terms, cons_idx|
          low = float_value(lower_bounds[cons_idx])
          up = float_value(upper_bounds[cons_idx])

          name = cons_name(cons_idx)
          terms = Ilp::TermArray.new(terms)

          if low == up
            model.enforce(name => terms == low)
          else
            model.enforce(name => terms >= low) if low != -Cbc::INF
            model.enforce(name => terms <= up) if up != Cbc::INF
          end
        end
      end

      OBJ_IGNORE = 0
      OBJ_MIN = 1
      OBJ_MAX = -1

      def objective(model)
        obj_sense = Cbc_wrapper.Cbc_getObjSense(cbc_model)
        return if obj_sense == OBJ_IGNORE

        coeffs = double_array(Cbc_wrapper.Cbc_getObjCoefficients(cbc_model))
        terms = (0...nb_vars).map { |i| model.vars[i] * coeffs[i] }

        if obj_sense == OBJ_MIN
          model.minimize(Cbc.add_all(terms))
        else
          model.maximize(Cbc.add_all(terms))
        end
      end

      def problem_name
        name = " " * 40
        Cbc_wrapper.Cbc_problemName(cbc_model, 40, name)
        CString.from_c(name)
      end

      def float_value(val)
        return Cbc::INF if val == Float::MAX
        return -Cbc::INF if val == -Float::MAX

        val
      end

      def nb_vars
        Cbc_wrapper.Cbc_getNumCols(cbc_model)
      end

      def nb_cons
        Cbc_wrapper.Cbc_getNumRows(cbc_model)
      end

      def var_name(var_idx)
        Cbc_wrapper.Cbc_getColName(cbc_model, var_idx, name_container, max_name_size)
        CString.from_c(name_container)
      end

      def cons_name(cons_idx)
        Cbc_wrapper.Cbc_getRowName(cbc_model, cons_idx, name_container, max_name_size)
        CString.from_c(name_container)
      end

      def name_container
        @name_container ||= " " * max_name_size
      end

      def max_name_size
        # Need to leave space for null char
        @max_name_size ||= Cbc_wrapper.Cbc_maxNameLength(cbc_model) + 1
      end

      def int_array(ptr)
        Cbc_wrapper::IntArray.frompointer(ptr)
      end

      def double_array(ptr)
        Cbc_wrapper::DoubleArray.frompointer(ptr)
      end
    end
  end
end
