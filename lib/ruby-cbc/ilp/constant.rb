module Ilp
  class Constant
    attr_accessor :value
    def initialize(value)
      raise ArgumentError, "Argument is not numeric" unless value.is_a? Numeric
      @value = value
    end

    def <=(other)
      other >= value
    end

    def <(other)
      other > value
    end

    def >=(other)
      other <= value
    end

    def >(other)
      other < value
    end

    def ==(other)
      other == value
    end

    def *(other)
      other * value
    end

    def +(other)
      other + value
    end

    def -(other)
      -1 * other + value
    end

    def to_s
      value.to_s
    end

    def pretty_print
      value.to_s
    end
  end
end
