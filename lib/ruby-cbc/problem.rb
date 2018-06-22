module Cbc
  class Problem
    attr_accessor :model, :variable_index, :crs, :continuous, :time_limit

    def self.from_model(model, continuous: false)
      crs = Util::CompressedRowStorage.from_model(model)
      from_compressed_row_storage(crs, continuous: continuous)
    end

    def self.from_compressed_row_storage(crs, continuous: false)
      new.tap do |p|
        p.model = crs.model
        p.variable_index = crs.variable_index
        p.crs = crs
        p.continuous = continuous
      end
    end

    def solve(params = {})
      @native_problem = NativeProblem.from_problem(self)
      @native_problem.solve(computed_params(params))
    end

    def value_of(var)
      @native_problem.value_of(var)
    end

    # Keep this one for back compatibility
    # rubocop:disable Naming/AccessorMethodName
    def set_time_limit(seconds)
      self.time_limit = seconds
    end
    # rubocop:enable Naming/AccessorMethodName

    def computed_params(params)
      return params unless time_limit
      { sec: time_limit }.merge(params)
    end

    def proven_optimal?
      @native_problem.proven_optimal?
    end

    def proven_infeasible?
      @native_problem.proven_infeasible?
    end

    def time_limit_reached?
      @native_problem.time_limit_reached?
    end

    def solution_limit_reached?
      @native_problem.solution_limit_reached?
    end

    def objective_value
      @native_problem.objective_value
    end

    # Returns the best know bound so far
    def best_bound
      @native_problem.best_bound
    end

    def find_conflict
      @find_conflict ||= ConflictSolver.new(self).find_conflict
    end

    def find_conflict_vars
      @find_conflict_vars ||= find_conflict.map(&:vars).flatten.uniq
    end

    def write
      @native_problem.write
    end
  end
end
