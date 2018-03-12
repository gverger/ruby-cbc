require 'spec_helper'

describe "Terms and vars" do
  let(:model) { Cbc::Model.new }
  let(:x) { model.int_var(name: 'x') }
  let(:y) { model.int_var(name: 'y') }
  let(:problem) { model.to_problem }

  ## Assertions...

  def objective?(expected)
    expect(model.objective.to_s.gsub(/\s+/, ' ').strip).to eq(expected)
  end

  def constraints?(*expected)
    expect(model.constraints.map(&:to_s)).to match_array(expected)
  end

  def optimal?(h)
    problem.solve
    expect(problem).to be_proven_optimal

    h.each do |var, expected_value|
      expect(problem.value_of(var)).to eq(expected_value)
    end
  end

  specify "var + var" do
    model.enforce(x + y <= 4)
    model.maximize(x)

    objective? "Maximize + x"
    optimal? x => 4, y => 0
  end

  specify "var + const" do
    model.enforce(x + 2 <= 4)
    model.maximize x

    objective? "Maximize + x"
    constraints? "+ x <= 2"
    optimal? x => 2
  end

  specify "const + var" do
    model.enforce(2 + x <= 4)
    model.maximize x

    objective? "Maximize + x"
    constraints? "+ x <= 2"
    optimal? x => 2
  end

  specify "var - var" do
    model.enforce(x - y <= 4)
    model.minimize(x)

    objective? "Minimize + x"
    optimal? x => 0, y => 0
  end

  specify "var - const" do
    model.enforce(x - 2 <= 4)
    model.maximize x

    objective? "Maximize + x"
    constraints? "+ x <= 6"
    optimal? x => 6
  end

  specify "const - var" do
    model.enforce(2 - x <= 4)
    model.minimize x

    objective? "Minimize + x"
    constraints? "- 1 x <= 2"
    optimal? x => 0
  end

  specify "-var" do
    model.maximize(-x)

    objective? "Maximize - 1 x"
    optimal? x => 0
  end

  specify "var * const" do
    model.maximize(x * -3)

    objective? "Maximize - 3 x"
    optimal? x => 0
  end

  specify "const * var" do
    model.maximize(-3 * x)

    objective? "Maximize - 3 x"
    optimal? x => 0
  end

  describe "Constraints" do
    specify "var + const <= const" do
      expect((x + 3 <= 14).to_s).to eq("+ x <= 11")
    end

    specify "var - const <= const" do
      expect((x - 3 <= 14).to_s).to eq("+ x <= 17")
    end

    specify "const + var <= const" do
      expect((3 + x <= 14).to_s).to eq("+ x <= 11")
    end

    specify "const - var <= const" do
      expect((3 - x <= 14).to_s).to eq("- 1 x <= 11")
    end

    specify "const - term <= const" do
      expect((3 - (4*x) <= 14).to_s).to eq("- 4 x <= 11")
    end

    specify "const - termarray <= const" do
      expect((3 - (4 * x + 4) <= 14).to_s).to eq('- 4 x <= 15')
    end
  end

end
