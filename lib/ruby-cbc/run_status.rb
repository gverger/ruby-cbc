module Cbc
  # This class is responsible for storing all info about an ILP execution
  # We can access wether or not it was successful, and the values of the variables
  class RunStatus
    FIELDS = %i[
      assignments
      optimal
      infeasible
      time_limit_reached
      solution_limit_reached
      objective_value
      best_bound
    ].freeze

    def initialize(fields)
      FIELDS.each do |field|
        instance_variable_set(:"@#{field}", fields[field])
      end
    end

    attr_reader :objective_value, :best_bound

    def proven_optimal?
      @optimal
    end

    def proven_infeasible?
      @infeasible
    end

    def time_limit_reached?
      @time_limit_reached
    end

    def solution_limit_reached?
      @solution_limit_reached
    end

    def value_of(variable)
      @assignments[variable]
    end
  end
end
