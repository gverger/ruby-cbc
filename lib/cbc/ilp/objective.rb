module Ilp
  class Objective

    MINIMIZE = :min
    MAXIMIZE = :max

    attr_accessor :terms, :objective_function
    def initialize(terms, objective_function = MAXIMIZE)
      @terms = terms
      @terms = Ilp::Term.new(@terms) if @terms.is_a? Ilp::Var
      @terms = Ilp::TermArray.new(@terms) if @terms.is_a? Ilp::Term
      @terms.normalize!
      cste = @terms.send(:pop_constant)
      puts "Removing constant [#{cste}] in objective" if cste != 0
      @objective_function = objective_function
    end

  end
end
