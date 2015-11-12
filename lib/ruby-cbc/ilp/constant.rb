module Ilp
  class Constant
    attr_accessor :value
    def initialize(value)
      raise ArgumentError, 'Argument is not numeric' unless value.is_a? Numeric
      @value = value
    end
    def <= (term)
      term >= value
    end
    def <(term)
      term > value
    end
    def >=(term)
      term <= value
    end
    def > (term)
      term < value
    end
    def ==(term)
      term == value
    end

    def *(term)
      term * value
    end
    
    def +(term)
      term + value
    end

    def -(term)
      -1 * term + value
    end

    def to_s
      value.to_s
    end

    def pretty_print
      value.to_s
    end
  end
end
