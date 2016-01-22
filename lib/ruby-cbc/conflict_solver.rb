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

    def infeasible?(model)
      problem = model.to_problem
      problem.solve
      problem.proven_infeasible?
    end
  end
end
