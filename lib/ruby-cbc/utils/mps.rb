module Cbc
  module Utils
    class Mps
      def initialize(mps_file)
        @mps_file = mps_file
      end

      def to_model
        cbc_model = Cbc_wrapper.Cbc_newModel
        Cbc_wrapper.Cbc_readMps(cbc_model, @mps_file)

        model = Utils::ProblemUnwrap.new(cbc_model).to_model
        Cbc_wrapper.Cbc_deleteModel(cbc_model)
        model
      end
    end
  end
end
