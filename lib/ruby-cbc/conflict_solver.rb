module Cbc

  class ConflictSolver

    def initialize(problem)
      # clone the model minus the objective
      @model = Model.new
      @model.vars = problem.model.vars
      @model.constraints = problem.model.constraints
      @problem = problem
    end

    # Assuming there is a conflict
    def find_conflict
      continuous = is_continuous_conflict?
      puts "continuous: #{continuous}"
      conflict_set = []
      crs = Util::CompressedRowStorage.from_model(@model)
      loop do
        range_idxs = first_failing(conflict_set.count, crs, continuous: continuous)
        return conflict_set if range_idxs.nil?
        puts "add constraints #{range_idxs}"

        # Check if conflict set is found
        conflict_set.concat crs.model.constraints[range_idxs]
        m = Model.new
        m.vars = conflict_set.flat_map(&:vars).uniq
        m.constraints = conflict_set
        problem = Problem.from_model(m, continuous: continuous)
        puts "infeasible?"
        return conflict_set if infeasible?(problem)

        crs = crs.restrict_to_n_constraints(range_idxs.max + 1)
        crs.move_constraint_to_start(range_idxs)
      end
      conflict_set
    end

    def is_continuous_conflict?
      # Same model without objective
      problem = Problem.from_model(@model, continuous: true)
      infeasible?(problem)
    end

  private
    # finds the first constraint from constraints that makes the problem infeasible
    def first_failing(conflict_set_size, crs, continuous: false, max_iterations: nil)
      min_nb_constraints = conflict_set_size
      max_nb_constraints = crs.nb_constraints + 1

      loop do
        if max_iterations
          break if max_iterations.zero?
          max_iterations -= 1
        end
        half_constraints = (max_nb_constraints + min_nb_constraints) / 2
        puts "Refining: [#{min_nb_constraints}:#{max_nb_constraints}] -> #{half_constraints}"
        crs2 = crs.restrict_to_n_constraints(half_constraints)
        problem = Problem.from_compressed_row_storage(crs2, continuous: continuous)
        if infeasible?(problem)
          max_nb_constraints = half_constraints
          puts "                                INFEAS"
        else
          min_nb_constraints = half_constraints
          puts "                                FEAS"
        end
        if max_nb_constraints - min_nb_constraints <= 1
          puts "found: max = #{max_nb_constraints} min = #{min_nb_constraints} nb = #{crs.nb_constraints}"
          return nil if max_nb_constraints > crs.nb_constraints
          return min_nb_constraints..(max_nb_constraints - 1)
        end
      end
      # Shouldn't come here if the whole problem is infeasible
      return nil
    end

    def infeasible?(problem)
      problem.solve
      problem.proven_infeasible?
    end
  end
end
