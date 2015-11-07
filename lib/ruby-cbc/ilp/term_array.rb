module Ilp
  class TermArray
    include Enumerable

    attr_accessor :terms

    def initialize(*terms)
      @terms = terms
    end

    def +(vars)
      if vars.is_a? Numeric
        @terms << vars
      elsif vars.is_a? Ilp::Var
        @terms << Ilp::Term.new(vars)
      elsif vars.is_a? Ilp::Term
        @terms << vars
      elsif vars.is_a? Ilp::TermArray
        @terms += vars.terms
      else
        raise ArgumentError, "Argument is not allowed: #{vars} of type #{vars.class}"
      end
      self
    end

    def -(vars)
      self + -1 * vars
    end

    def *(mult)
      raise ArgumentError, 'Argument is not numeric' unless mult.is_a? Numeric
      @terms.map! { |term| term * mult }
      self
    end

    # cste + nb * var + nb * var...
    def normalize!
      constant = @terms.select{ |t| t.is_a? Numeric }.inject(:+)
      hterms = @terms.select{ |t| t.is_a? Ilp::Term }.group_by(&:var)
      @terms = []
      constant ||= 0
      @terms << constant
      hterms.each do |v, ts| 
        t = ts.inject(Ilp::Term.new(v, 0)) { |v1, v2| v1.mult += v2.mult; v1 }
        terms << t if t.mult != 0
      end
      self
    end

    def <=(value)
      Ilp::Constraint.new(self, Ilp::Constraint::LESS_OR_EQ, value)
    end

    def >=(value)
      Ilp::Constraint.new(self, Ilp::Constraint::GREATER_OR_EQ, value)
    end

    def ==(value)
      Ilp::Constraint.new(self, Ilp::Constraint::EQUALS, value)
    end

    def coerce(value)
      [Ilp::Constant.new(value), self]
    end

    def each(&block)
      @terms.each(&block)
    end

    def to_s
      @terms.join(' + ')
    end

  private
    # Must be normalized!
    def pop_constant
      terms.slice!(0)
    end
  end
end
