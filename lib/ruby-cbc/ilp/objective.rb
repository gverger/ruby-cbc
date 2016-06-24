module Ilp
  class Objective
    MINIMIZE = :min
    MAXIMIZE = :max

    attr_accessor :terms, :objective_function
    def initialize(terms, objective_function = MAXIMIZE)
      @terms = terms
      @terms = Ilp::Term.new(@terms) if @terms.is_a? Ilp::Var
      @terms = Ilp::TermArray.new([@terms]) if @terms.is_a? Ilp::Term
      @terms.normalize!
      @terms.send(:pop_constant)
      @objective_function = objective_function
    end

    def to_s
      "#{(@objective_function == :max ? 'Maximize' : 'Minimize')}\n  #{terms}"
    end
  end
end
