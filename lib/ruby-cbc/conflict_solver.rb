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
      conflict_set = []
      all_constraints = @model.constraints
      nb_constraints = all_constraints.count
      loop do
        m = Model.new
        m.vars = conflict_set.flat_map(&:vars).uniq
        m.constraints = conflict_set
        problem = Problem.new(m, continuous: continuous)
        return conflict_set if infeasible?(problem)
        constraint_idx = first_failing(conflict_set, all_constraints, nb_constraints, continuous: continuous)
        return conflict_set if constraint_idx.nil?

        nb_constraints = constraint_idx
        conflict_set << all_constraints[constraint_idx]
      end
    end

    def is_continuous_conflict?
      # Same model without objective
      problem = Problem.new(@model, continuous: true)
      infeasible?(problem)
    end

  private
    # finds the first constraint from constraints that makes the problem infeasible
    def first_failing(conflict_set, constraints, nb_constraints, continuous: false)
      min_nb_constraints = 0
      max_nb_constraints = nb_constraints + 1

      loop do
        half_constraints = (max_nb_constraints + min_nb_constraints) / 2
        problem = Problem.new(@model,
                              sub_problem_of: @problem,
                              nb_constraints: half_constraints,
                              additional_constraints: conflict_set,
                              continuous: continuous)
        if infeasible?(problem)
          max_nb_constraints = half_constraints
        else
          min_nb_constraints = half_constraints
        end
        if max_nb_constraints - min_nb_constraints <= 1
          return nil if max_nb_constraints > nb_constraints
          return max_nb_constraints - 1
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
