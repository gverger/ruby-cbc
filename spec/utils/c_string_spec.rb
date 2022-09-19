require "spec_helper"

module Cbc
  module Utils
    describe CString do
      it "returns the ruby string when trailing null chars exist" do
        bytes = [78, 65, 77, 69, 0, 0, 0, 0, 0, 0]
        c_string = bytes.map(&:chr).join
        expect(CString.from_c(c_string)).to eq "NAME"
      end

      it "returns the ruby string when no trailing space exist" do
        bytes = [78, 65, 77, 69]
        c_string = bytes.map(&:chr).join
        expect(CString.from_c(c_string)).to eq "NAME"
      end

      it "returns the empty string when the c string is only null chars" do
        bytes = [0]
        c_string = bytes.map(&:chr).join
        expect(CString.from_c(c_string)).to be_empty
      end

      it "returns the empty string when the c string empty" do
        c_string = ""
        expect(CString.from_c(c_string)).to be_empty
      end
    end
  end
end
