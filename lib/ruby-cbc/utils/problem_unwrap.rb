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

      def variables(model)
        nb_vars = Cbc_wrapper.Cbc_getNumCols(cbc_model)
        lower_bounds = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getColLower(cbc_model))
        upper_bounds = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getColUpper(cbc_model))
        nb_vars.times do |i|
          Cbc_wrapper.Cbc_getColName(cbc_model, i, name_container, max_name_size)
          name = CString.from_c(name_container)

          range = float_value(lower_bounds[i])..float_value(upper_bounds[i])
          if Cbc_wrapper.Cbc_isInteger(cbc_model, i) == 1
            model.int_var(range, name: name)
          else
            model.cont_var(range, name: name)
          end
        end
        model.to_s
      end

      def constraints(model)
        nb_vars = Cbc_wrapper.Cbc_getNumCols(cbc_model)
        nb_cons = Cbc_wrapper.Cbc_getNumRows(cbc_model)
        lower_bounds = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getRowLower(cbc_model))
        upper_bounds = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getRowUpper(cbc_model))

        nb_elements = Cbc_wrapper.Cbc_getNumElements(cbc_model)
        starts = Cbc_wrapper::IntArray.frompointer(Cbc_wrapper.Cbc_getVectorStarts(cbc_model))
        indices = Cbc_wrapper::IntArray.frompointer(Cbc_wrapper.Cbc_getIndices(cbc_model))
        elements = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getElements(cbc_model))

        cons_terms = Array.new(nb_cons) { [] }

        var_idx = 0
        while var_idx < nb_vars
          from = starts[var_idx]
          to = var_idx == nb_vars - 1 ? nb_elements : starts[var_idx + 1]

          puts "new values for #{var_idx}"
          (from...to).each do |i|
            cons_idx = indices[i]
            element = elements[i]
            puts "#{cons_idx}  : #{element}"
            cons_terms[cons_idx] << model.vars[var_idx] * element
          end

          var_idx += 1
        end

        cons_terms.each_with_index do |terms, cons_idx|
          low = float_value(lower_bounds[cons_idx])
          up = float_value(upper_bounds[cons_idx])

          Cbc_wrapper.Cbc_getRowName(cbc_model, cons_idx, name_container, max_name_size)
          name = CString.from_c(name_container)
          terms = Ilp::TermArray.new(terms)
          puts terms

          if low == up
            model.enforce(name => terms == low)
          else
            model.enforce(name => terms >= low) if low != -Cbc::INF
            model.enforce(name => terms <= up) if up != Cbc::INF
          end
        end

        model.to_s
      end

      OBJ_IGNORE = 0
      OBJ_MIN = 1
      OBJ_MAX = -1

      def objective(model)
        obj_sense = Cbc_wrapper.Cbc_getObjSense(cbc_model)
        return if obj_sense == OBJ_IGNORE

        nb_vars = Cbc_wrapper.Cbc_getNumCols(cbc_model)
        coeffs = Cbc_wrapper::DoubleArray.frompointer(Cbc_wrapper.Cbc_getObjCoefficients(cbc_model))
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

      def name_container
        @name_container ||= " " * max_name_size
      end

      def max_name_size
        # Need to leave space for null char
        @max_name_size ||= Cbc_wrapper.Cbc_maxNameLength(cbc_model) + 1
      end

      def float_value(v)
        return Cbc::INF if v == Float::MAX
        return -Cbc::INF if v == -Float::MAX

        v
      end
    end
  end
end
