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

  end
end
