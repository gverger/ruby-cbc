module Ilp
  class Constraint
    LESS_OR_EQ = :less_or_eq
    GREATER_OR_EQ = :greater_or_eq
    EQUALS = :equals

    attr_accessor :terms, :type, :bound, :function_name

    def initialize(terms, type, bound)
      @terms = terms - bound
      @terms.normalize!
      @bound = -1 * @terms.send(:pop_constant)
      @type = type
    end

    def vars
      terms.vars
    end

    def to_function_s
      "#{function_name || 'constraint'}(#{vars.map!(&:name).join(', ')})"
    end

    SIGN_TO_STRING = {
      LESS_OR_EQ => "<=",
      GREATER_OR_EQ => ">=",
      EQUALS => "="
    }

    def to_s
      sign = SIGN_TO_STRING[@type] || "??"
      "#{@terms} #{sign} #{@bound}"
    end
  end
end
