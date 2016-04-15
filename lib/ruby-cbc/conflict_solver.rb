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
      all_constraints = @model.constraints.clone
      nb_constraints = all_constraints.count
      loop do
        m = Model.new
        m.vars = conflict_set.flat_map(&:vars).uniq
        m.constraints = conflict_set
        problem = Problem.new(m, continuous: continuous)
        puts "infeasible?"
        return conflict_set if infeasible?(problem)
        constraint_idx = first_failing(conflict_set, all_constraints, nb_constraints, continuous: continuous)
        return conflict_set if constraint_idx.nil?
        puts "add constraint #{constraint_idx}"

        nb_constraints = constraint_idx
        conflict_set << all_constraints.delete_at(constraint_idx)
        all_constraints = all_constraints[0, nb_constraints]
      end
      conflict_set
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
      max_nb_constraints = constraints.count + 1

      loop do
        half_constraints = (max_nb_constraints + min_nb_constraints) / 2
        puts "Refining: [#{min_nb_constraints}:#{max_nb_constraints}] -> #{half_constraints}"
        m = Model.new
        m.vars = @model.vars
        m.constraints = conflict_set + constraints
        problem = Problem.new(m,
                              nb_constraints: conflict_set.count + half_constraints,
                              continuous: continuous)
        if infeasible?(problem)
          max_nb_constraints = half_constraints
          puts "                                INFEAS"
        else
          min_nb_constraints = half_constraints
          puts "                                FEAS"
        end
        if max_nb_constraints - min_nb_constraints <= 1
          puts "found: max = #{max_nb_constraints} min = #{min_nb_constraints} nb = #{nb_constraints}"
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
