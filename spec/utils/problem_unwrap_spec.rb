# frozen_string_literal: true

require "spec_helper"

module Cbc
  module Utils
    describe ProblemUnwrap do
      def problem_unwrap
        model = Cbc_wrapper.Cbc_newModel
        Cbc_wrapper.Cbc_readMps(model, "./spec/utils/prob.mps")
        ProblemUnwrap.new model
      end

      it "returns the right name" do
        p = problem_unwrap
        expect(p.to_model.name).to eq "EXAMPLE"
      end

      it "gets the variables right" do
        p = problem_unwrap
        vars = p.to_model.vars
        expect(vars.size).to eq 8

        col01 = vars.find { |var| var.name == "COL01" }
        expect(col01).to_not be_nil
        expect(col01).to have_attributes(lower_bound: 2.5, upper_bound: Cbc::INF, kind: :continuous)

        col02 = vars.find { |var| var.name == "COL02" }
        expect(col02).to_not be_nil
        expect(col02).to have_attributes(lower_bound: 0, upper_bound: 4.1, kind: :continuous)

        col03 = vars.find { |var| var.name == "COL03" }
        expect(col03).to_not be_nil
        expect(col03).to have_attributes(lower_bound: 0, upper_bound: 1.0, kind: :integer)

        col05 = vars.find { |var| var.name == "COL05" }
        expect(col05).to_not be_nil
        expect(col05).to have_attributes(lower_bound: 0.5, upper_bound: 4.0, kind: :continuous)
      end

      it "gets the constraints right" do
        p = problem_unwrap
        constraints = p.to_model.constraints
        expect(constraints.size).to eq 7

        row01 = constraints.find { |cons| cons.function_name == "ROW01" }
        expect(row01).to_not be_nil
        expect(row01.to_s)
          .to eq "+ 3.0 COL01 + COL02 - 2.0 COL04 - 1.0 COL05 - 1.0 COL08 >= 2.5"

        row02 = constraints.find { |cons| cons.function_name == "ROW02" }
        expect(row02).to_not be_nil
        expect(row02.to_s)
          .to eq "+ 2.0 COL02 + 1.1 COL03 <= 2.1"
      end

      it "gets the objective right" do
        p = problem_unwrap
        obj = p.to_model.objective

        expect(obj.to_s).to eq "Minimize\n  + COL01 + 2.0 COL05 - 1.0 COL08"
      end
    end
  end
end
