%module cbc_wrapper

%include "typemaps.i"
%include "carrays.i"

%{
#include "Coin_C_defines.h"
#include "Cbc_C_Interface.h"
%}

%array_class(int, IntArray)
%array_class(double, DoubleArray)
%array_class(CoinBigIndex, BigIndexArray)

%include "Coin_C_defines.h"
%include "Cbc_C_Interface.h"
