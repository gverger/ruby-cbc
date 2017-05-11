module Ilp
  class Term
    attr_reader :mult, :var

    def initialize(var, mult = 1)
      @mult = mult
      @var = var
    end

    def +(other)
      Ilp::TermArray.new([self]) + other
    end

    def -(other)
      Ilp::TermArray.new([self]) - other
    end

    def ==(other)
      Ilp::TermArray.new([self]) == other
    end

    def <=(other)
      Ilp::TermArray.new([self]) <= other
    end

    def >=(other)
      Ilp::TermArray.new([self]) >= other
    end

    def combine_in(other_term)
      return Term.new(var, mult) if other_term.nil?
      other_term.mult += mult
      other_term
    end

    def *(other)
      raise ArgumentError, "Argument is not numeric" unless other.is_a? Numeric
      Ilp::Term.new(@var, @mult * other)
    end

    def coerce(num)
      [Ilp::TermArray.new([self]), num]
    end

    def to_s
      str = "++-"[mult <=> 0] << " "
      str << mult.abs.to_s << " " if mult != 1
      str << var.to_s
    end
  end
end
