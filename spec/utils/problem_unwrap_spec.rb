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
        expect(p.problem_name).to eq "EXAMPLE"
      end

      it "gets the max name size" do
        p = problem_unwrap
        expect(p.max_name_size).to eq 6
      end
    end
  end
end
