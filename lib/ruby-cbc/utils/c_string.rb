# frozen_string_literal: true

module Cbc
  module Utils
    class CString
      NULL_CHAR = "\x00"

      # @param null_terminated_string <String>
      def self.from_c(null_terminated_string)
        null_index = null_terminated_string.index(NULL_CHAR)
        return null_terminated_string if null_index.nil?

        null_terminated_string[0, null_index]
      end
    end
  end
end
