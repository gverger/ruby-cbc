module Ilp
  class Var
    attr_accessor :kind, :name, :lower_bound, :upper_bound

    BINARY_KIND = :binary
    INTEGER_KIND = :integer
    CONTINUOUS_KIND = :continuous

    def initialize(name: nil, kind: INTEGER_KIND, lower_bound: nil, upper_bound: nil)
      @kind = kind
      @name = name
      @name = ('a'..'z').to_a.shuffle[0,8].join if name.nil?
      @lower_bound = lower_bound
      @upper_bound = upper_bound
    end

    def bounds=(range)
      @lower_bound = range.min
      @upper_bound = range.max
    end

    def bounds
      @lower_bound..@upper_bound
    end

    def +(vars)
      Ilp::Term.new(self) + vars
    end

    def -(vars)
      Ilp::Term.new(self) - vars
    end

    def -@
      Ilp::Term.new(self, -1)
    end

    def *(mult)
      Ilp::Term.new(self) * mult
    end

    def ==(vars)
      Ilp::Term.new(self) == vars
    end

    def <=(vars)
      Ilp::Term.new(self) <= vars
    end

    def >=(vars)
      Ilp::Term.new(self) >= vars
    end

    def coerce(num)
      [Ilp::Term.new(self), num]
    end

  end

end
