require "ffi"

module Cbc
  module Cbc_wrapper
    extend FFI::Library

    ffi_lib_flags :lazy, :global
    ffi_lib "CbcSolver"

    typedef :pointer, :model
    typedef :pointer, :int_array
    typedef :pointer, :double_array

    attach_function :Cbc_newModel, [], :model
    attach_function :Cbc_loadProblem, %i[model int int int_array int_array double_array pointer pointer double_array pointer pointer], :void
    attach_function :Cbc_setObjSense, %i[model double], :void
    attach_function :Cbc_setContinuous, %i[model int], :void
    attach_function :Cbc_setColUpper, %i[model int double], :void
    attach_function :Cbc_setColLower, %i[model int double], :void
    attach_function :Cbc_setRowUpper, %i[model int double], :void
    attach_function :Cbc_setRowLower, %i[model int double], :void
    attach_function :Cbc_setInteger, %i[model int], :void
    attach_function :Cbc_setParameter, %i[model string string], :void
    attach_function :Cbc_solve, [:model], :int
    attach_function :Cbc_getColSolution, [:model], :double_array
    attach_function :Cbc_isProvenOptimal, [:model], :int
    attach_function :Cbc_isProvenInfeasible, [:model], :int
    attach_function :Cbc_writeMps, %i[model string], :void
  end
end
