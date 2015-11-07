module Ilp
  class Term

    attr_accessor :mult, :var

    def initialize(var, mult = 1)
      @mult = mult
      @var = var
    end

    def +(vars)
      Ilp::TermArray.new(self) + vars
    end

    def -(vars)
      Ilp::TermArray.new(self) - vars
    end

    def ==(vars)
      Ilp::TermArray.new(self) == vars
    end

    def <=(vars)
      Ilp::TermArray.new(self) <= vars
    end

    def >=(vars)
      Ilp::TermArray.new(self) >= vars
    end


    def *(mult)
      raise ArgumentError, 'Argument is not numeric' unless mult.is_a? Numeric
      Ilp::Term.new(@var, @mult * mult)
    end

    def coerce(num)
      [Ilp::TermArray.new(self), num]
    end

    def to_s
      "#{mult} #{var.name}"
    end

  end
end
