module Cbc

  class ConflictSolver

    def initialize(problem)
      # clone the model minus the objective
      @model = Model.new
      @model.vars = problem.model.vars
      @model.constraints = problem.model.constraints
      @problem = problem
    end

    def find_conflict
      crs = Util::CompressedRowStorage.from_model(@model)
      continuous = is_continuous_conflict?(crs)
      unless continuous
        p = Problem.from_compressed_row_storage(crs, continuous: false)
        return [] unless infeasible?(p)
      end
      clusters = [crs.nb_constraints]
      max_iter = 1
      conflict_set_size = 0
      loop do
        range_idxs = first_failing(conflict_set_size, crs, continuous: continuous, max_iterations: max_iter)
        break if range_idxs.nil?
        puts "RANGE #{range_idxs}"
        crs = crs.restrict_to_n_constraints(range_idxs.max + 1)
        crs.move_constraint_to_start(range_idxs)
        clusters.insert(0, range_idxs.size)
        clusters[-1] = range_idxs.min - conflict_set_size
        conflict_set_size += range_idxs.size

        # Test conflict set
        crs2 = crs.restrict_to_n_constraints(conflict_set_size)
        problem = Problem.from_compressed_row_storage(crs2, continuous: continuous)
        if infeasible?(problem)
          puts "CONFLICT"
          clusters.delete_at(-1)
          break if clusters.size == conflict_set_size

          crs = crs2
        end

        nb_clusters_one_constraint = 0
        clusters.reverse_each do |nb_constraints|
          break if nb_constraints > 1
          nb_clusters_one_constraint += 1
        end
        if nb_clusters_one_constraint > 0
          crs.move_constraint_to_start((crs.nb_constraints - nb_clusters_one_constraint)..(crs.nb_constraints - 1))
          clusters[nb_clusters_one_constraint, clusters.size - nb_clusters_one_constraint] =
            clusters[0, clusters.size - nb_clusters_one_constraint]
          clusters[0, nb_clusters_one_constraint] = Array.new(nb_clusters_one_constraint, 1)
        end

        conflict_set_size = crs.nb_constraints - clusters[-1]
        puts "CLUSTERS #{clusters.inspect}"
        puts "VARS #{crs.col_idx.uniq.size}"
      end
      crs.model.constraints[0, conflict_set_size]
    end

    def is_continuous_conflict?(crs)
      problem = Problem.from_compressed_row_storage(crs, continuous: true)
      infeasible?(problem)
    end

  private
    # finds the first constraint from constraints that makes the problem infeasible
    def first_failing(conflict_set_size, crs, continuous: false, max_iterations: nil)
      min_idx = conflict_set_size
      max_idx = crs.nb_constraints - 1

      loop do
        unless max_iterations.nil?
          return min_idx..max_idx if max_iterations <= 0
          max_iterations -= 1
        end
        half_constraint_idx = (max_idx + min_idx) / 2
        puts "Refining: [#{min_idx}:#{max_idx}] -> #{half_constraint_idx}"
        crs2 = crs.restrict_to_n_constraints(half_constraint_idx + 1)
        problem = Problem.from_compressed_row_storage(crs2, continuous: continuous)
        if infeasible?(problem)
          max_idx = half_constraint_idx
          puts "                                INFEAS"
        else
          min_idx = half_constraint_idx + 1
          puts "                                FEAS"
        end
        if max_idx == min_idx
          puts "found: max = #{max_idx} min = #{min_idx} nb = #{crs.nb_constraints}"
          return nil if max_idx > crs.nb_constraints
          return min_idx..max_idx
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
