module Ilp
  class Var
    attr_accessor :kind, :name, :lower_bound, :upper_bound

    BINARY_KIND = :binary
    INTEGER_KIND = :integer
    CONTINUOUS_KIND = :continuous

    def initialize(name: nil, kind: INTEGER_KIND, lower_bound: nil, upper_bound: nil)
      @kind = kind
      @name = name
      @name = ("a".."z").to_a.sample(8).join if name.nil?
      @lower_bound = lower_bound
      @upper_bound = upper_bound
    end

    def bounds=(range)
      @lower_bound = range.min
      @upper_bound = range.max
    end

    def continuous?
      kind == CONTINUOUS_KIND
    end

    def bounds
      @lower_bound..@upper_bound
    end

    def +(other)
      Ilp::Term.new(self) + other
    end

    def -(other)
      Ilp::Term.new(self) - other
    end

    def -@
      Ilp::Term.new(self, -1)
    end

    def *(other)
      Ilp::Term.new(self) * other
    end

    def ==(other)
      Ilp::Term.new(self) == other
    end

    def <=(other)
      Ilp::Term.new(self) <= other
    end

    def >=(other)
      Ilp::Term.new(self) >= other
    end

    def coerce(num)
      [Ilp::Constant.new(num), self]
    end

    def to_s
      name.to_s
    end
  end
end
