require "forwardable"

module Ilp
  class TermArray
    extend Forwardable

    attr_accessor :terms
    def_delegators :@terms, :map, :each, :size

    def initialize(terms)
      @terms = terms
    end

    def +(other)
      new_terms = terms.dup
      case other
      when Numeric
        new_terms << other
      when Ilp::Var
        new_terms << Ilp::Term.new(other)
      when Ilp::Term
        new_terms << other
      when Ilp::TermArray
        new_terms.concat(other.terms)
      else
        raise ArgumentError, "Argument is not allowed: #{other} of type #{other.class}"
      end
      TermArray.new(new_terms)
    end

    def -(other)
      self + -1 * other
    end

    def *(other)
      raise ArgumentError, "Argument is not numeric" unless other.is_a? Numeric
      new_terms = terms.map { |term| term * other }
      TermArray.new(new_terms)
    end

    # cste + nb * var + nb * var...
    def normalize!
      constant = 0
      hterms = {}
      @terms.each do |term|
        case term
        when Numeric
          constant += term
        when Ilp::Term
          v = term.var
          hterms[v] ||= Ilp::Term.new(v, 0)
          hterms[v].mult += term.mult
        end
      end
      reduced = hterms.map { |_, term| term unless term.mult.zero? }
      reduced.compact!
      @terms = [constant].concat reduced
      self
    end

    def <=(other)
      Ilp::Constraint.new(self, Ilp::Constraint::LESS_OR_EQ, other)
    end

    def >=(other)
      Ilp::Constraint.new(self, Ilp::Constraint::GREATER_OR_EQ, other)
    end

    def ==(other)
      Ilp::Constraint.new(self, Ilp::Constraint::EQUALS, other)
    end

    def coerce(value)
      [Ilp::Constant.new(value), self]
    end

    def to_s
      @terms.map(&:to_s).join(" ")
    end

    def vars
      @terms.map(&:var)
    end

    private

    # Must be normalized!
    def pop_constant
      terms.slice!(0)
    end
  end
end
