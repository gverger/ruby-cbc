require "spec_helper"

describe Cbc do
  it "has a version number" do
    expect(Cbc::VERSION).not_to be nil
  end

  it "runs" do
    m = Cbc::Model.new
    x = m.int_var
    m.enforce(2 * x <= 4)
    m.maximize(x * 3)
    p = m.to_problem
    p.solve
    expect(p.proven_optimal?).to eq(true)
    expect(p.value_of(x)).to eq(2)
  end

  it "shows when infeasible" do
    m = Cbc::Model.new
    x = m.int_var
    m.enforce(2 * x <= 4)
    m.enforce(x >= 3)
    m.maximize(x * 3)
    p = m.to_problem
    p.solve
    expect(p.proven_optimal?).to eq(false)
    expect(p.proven_infeasible?).to eq(true)
  end

  it "find no conflict when feasible" do
    m = Cbc::Model.new
    x = m.int_var
    m.enforce(2 * x <= 4)
    m.maximize(x * 3)
    p = m.to_problem
    p.solve
    expect(p.proven_optimal?).to eq(true)
    expect(p.find_conflict).to be_empty
    expect(p.find_conflict_vars).to be_empty
  end

  it "find a conflict when infeasible" do
    m = Cbc::Model.new
    x = m.int_var(name: "x")
    y = m.int_var(name: "y")
    m.enforce(sup_1: x >= 1)
    m.enforce(inf_5: x + y <= 5)
    m.enforce(sup_6: y >= 6)
    m.maximize(x * 3)
    p = m.to_problem
    p.solve
    expect(p.proven_optimal?).to eq(false)
    expect(p.proven_infeasible?).to eq(true)
    expect(p.find_conflict.map(&:to_function_s).sort).to eq(["inf_5(x, y)", "sup_6(y)"].sort)
    expect(p.find_conflict_vars.map(&:name).sort).to eq(%w[x y].sort)
  end

  it "is ok with infinite bounds" do
    m = Cbc::Model.new

    x = m.int_var(-Cbc::INF..Cbc::INF)

    m.enforce(x <= -2)
    m.maximize(x)

    p = m.to_problem
    p.solve

    expect(p.proven_optimal?).to eq(true)
    expect(p.value_of(x)).to eq(-2)
  end

  it "can maximize" do
    m = Cbc::Model.new
    x = m.int_var(0..10)
    m.maximize(x)
    p = m.to_problem
    p.solve

    expect(p.proven_optimal?).to eq(true)
    expect(p.value_of(x)).to eq(10)
  end

  it "can minimize" do
    m = Cbc::Model.new
    x = m.int_var(4..10)
    m.minimize(x)
    p = m.to_problem
    p.solve

    expect(p.proven_optimal?).to eq(true)
    expect(p.value_of(x)).to eq(4)
  end

  it "can solve a problem without optimization" do
    m = Cbc::Model.new
    x = m.int_var(4..10)
    p = m.to_problem
    p.solve

    expect(p.proven_optimal?).to eq(true)
    expect(p.value_of(x)).to eq(4)
  end

  it "can handle NIL objective" do
    m = Cbc::Model.new
    x = m.int_var(4..10)
    m.minimize(nil)
    p = m.to_problem
    p.solve

    expect(p.proven_optimal?).to eq(true)
    expect(p.value_of(x)).to eq(4)
  end

  it "process a simple problem" do
    # The same Brief Example as found in section 1.3 of
    # glpk-4.44/doc/glpk.pdf.
    #
    # maximize
    #   z = 10 * x1 + 6 * x2 + 4 * x3
    #
    # subject to
    #   p:      x1 +     x2 +     x3 <= 100
    #   q: 10 * x1 + 4 * x2 + 5 * x3 <= 600
    #   r:  2 * x1 + 2 * x2 + 6 * x3 <= 300
    #
    # where all variables are non-negative
    #   x1 >= 0, x2 >= 0, x3 >= 0
    #
    m = Cbc::Model.new
    x1, x2, x3 = m.int_var_array(3, 0..Cbc::INF)
    m.maximize(10 * x1 + 6 * x2 + 4 * x3)

    m.enforce(x1 + x2 + x3 <= 100)
    m.enforce(10 * x1 + 4 * x2 + 5 * x3 <= 600)
    m.enforce(2 * x1 + 2 * x2 + 6 * x3 <= 300)

    p = m.to_problem

    p.solve

    expect(p.proven_optimal?).to eq(true)
    {
      x1 => 33,
      x2 => 67,
      x3 => 0
    }.each do |var, value|
      expect(p.value_of(var)).to eq(value)
    end
  end

  it "can be printed" do
    m = Cbc::Model.new
    x = m.int_var(name: "x")
    m.enforce(2 * x <= 4)
    m.maximize(x * 3)
    expect(m.to_s).to eq(
      <<-OUTPUT.gsub(/^        /, "") # Not very robust with code indentation
        Maximize
          + 3 x

        Subject To
          + 2 x <= 4

        Bounds
          -inf <= x <= +inf

        Generals
          x

        End
      OUTPUT
    )
  end
end
