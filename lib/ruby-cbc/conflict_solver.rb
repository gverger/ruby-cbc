module Cbc

  class ConflictSolver

    def initialize(model)
     @model = model
    end

    # Assuming there is a conflict
    def find_conflict
      continuous = is_continuous_conflict?
      conflict_set = []
      all_constraints = @model.constraints.to_a
      nb_constraints = all_constraints.count
      loop do
        m = Model.new
        m.vars = @model.vars
        m.enforce(conflict_set)
        return conflict_set if infeasible?(m, continuous: continuous)

        constraint_idx = first_failing(conflict_set, all_constraints, nb_constraints, continuous: continuous)
        return conflict_set if !constraint_idx

        nb_constraints = constraint_idx
        conflict_set << all_constraints[constraint_idx]
      end
    end

    def is_continuous_conflict?
      # Same model without objective
      model = Model.new
      model.vars = @model.vars
      model.constraints = @model.constraints
      infeasible?(model, continuous: true)
    end

  private
    # finds the first constraint from constraints that makes the problem infeasible
    def first_failing(conflict_set, constraints, nb_constraints, continuous: false)
      min_nb_constraints = 0
      max_nb_constraints = nb_constraints + 1

      loop do
        m = Model.new
        m.vars = @model.vars
        m.enforce(conflict_set)

        half_constraints = (max_nb_constraints + min_nb_constraints) / 2
        m.enforce(constraints.take(half_constraints))
        if infeasible?(m, continuous: continuous)
          max_nb_constraints = half_constraints
        else
          min_nb_constraints = half_constraints
        end
        if max_nb_constraints - min_nb_constraints <= 1
          return nil if max_nb_constraints > constraints.count
          return max_nb_constraints - 1
        end
      end
      # Shouldn't come here if the whole problem is infeasible
      return nil
    end

    def infeasible?(model, continuous: false)
      problem = Problem.new(model, continuous: continuous)
      problem.solve
      problem.proven_infeasible?
    end
  end
end
