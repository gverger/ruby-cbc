module Ilp
  class Term
    attr_reader :var
    attr_accessor :mult

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
      return Term.new(var, mult) unless other_term
      raise "Terms cannot be combined: #{self} and #{other_term}" unless var.equal? other_term.var
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
