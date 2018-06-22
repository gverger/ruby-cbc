require "forwardable"

module Cbc
  class Problem
    extend Forwardable

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

    attr_reader :last_run_status
    def solve(params = {})
      @native_problem = NativeProblem.from_problem(self)
      @last_run_status = @native_problem.solve(computed_params(params))
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

    def_delegators :last_run_status,
                   :proven_optimal?,
                   :proven_infeasible?,
                   :time_limit_reached?,
                   :solution_limit_reached?,
                   :objective_value,
                   :best_bound,
                   :value_of

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
