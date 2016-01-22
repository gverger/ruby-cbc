module Cbc

  class ConflictSolver

    def initialize(model)
     @model = model
    end

    # Assuming there is a conflict
    def find_conflict
      conflict_set = []
      loop do
        new_model = Model.new
        new_model.vars = @model.vars

        new_model.enforce(conflict_set)

        # No objective function
        if infeasible?(new_model)
          return conflict_set
        end

        conflict_detected = false
        @model.constraints.each do |constraint|
          new_model.enforce(constraint)
          if infeasible?(new_model)
            conflict_detected = true
            conflict_set << constraint
            break
          end
        end
        if !conflict_detected
          return conflict_set # should be empty
        end
      end
    end

    def rec_find_conflict
      rec_find([], [], @model.constraints.to_a)
    end

    def rec_find(background, conflict_set, to_test)
      new_model = Model.new
      new_model.vars = @model.vars
      new_model.enforce(conflict_set)
      new_model.enforce(background)

      conflict_constraint = first_failing(new_model, to_test)

      return [] if conflict_constraint.nil?

      new_conflicts = [conflict_constraint]
      to_test -= new_conflicts

      split = split(to_test)
      new_conflicts += rec_find(background + split[0], conflict_set + new_conflicts, split[1])
      new_conflicts += rec_find(background, conflict_set + new_conflicts, split[0])

      new_conflicts
    end

    def split(array)
      split = array.each_slice(array.count / 2 + 1).to_a
      [
        split[0] || [],
        split[1] || []
      ]
    end

    # finds the first constraint from constraints that makes the problem infeasible
    def first_failing(model, constraints)
      return nil if infeasible?(model)

      min_nb_constraints = 1
      max_nb_constraints = constraints.count

      loop do
      m = Model.new
      m.vars = model.vars
      m.constraints = model.constraints

      nb_constraints = (max_nb_constraints + min_nb_constraints) / 2
      m.enforce(constraints.take(nb_constraints))
      if infeasible?(m)
        max_nb_constraints = nb_constraints
      else
        min_nb_constraints = nb_constraints
      end
      if max_nb_constraints - min_nb_constraints <= 1
        return constraints[max_nb_constraints - 1]
      end

      end
      # Shouldn't come here if the whole problem is infeasible
      return nil
    end

    def infeasible?(model)
      problem = model.to_problem
      problem.solve
      problem.proven_infeasible?
    end
  end
end
