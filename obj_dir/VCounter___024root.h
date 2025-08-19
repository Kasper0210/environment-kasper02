// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design internal header
// See VCounter.h for the primary calling header

#ifndef VERILATED_VCOUNTER___024ROOT_H_
#define VERILATED_VCOUNTER___024ROOT_H_  // guard

#include "verilated.h"


class VCounter__Syms;

class alignas(VL_CACHE_LINE_BYTES) VCounter___024root final : public VerilatedModule {
  public:

    // DESIGN SPECIFIC STATE
    VL_IN8(clk,0,0);
    VL_IN8(rst,0,0);
    CData/*0:0*/ __VstlFirstIteration;
    CData/*0:0*/ __Vtrigprevexpr___TOP__clk__0;
    CData/*0:0*/ __Vtrigprevexpr___TOP__rst__0;
    CData/*0:0*/ __VactContinue;
    VL_IN16(max,8,0);
    VL_OUT16(out,8,0);
    SData/*8:0*/ Counter__DOT__cnt;
    IData/*31:0*/ __VactIterCount;
    VlTriggerVec<1> __VstlTriggered;
    VlTriggerVec<2> __VactTriggered;
    VlTriggerVec<2> __VnbaTriggered;

    // INTERNAL VARIABLES
    VCounter__Syms* const vlSymsp;

    // CONSTRUCTORS
    VCounter___024root(VCounter__Syms* symsp, const char* v__name);
    ~VCounter___024root();
    VL_UNCOPYABLE(VCounter___024root);

    // INTERNAL METHODS
    void __Vconfigure(bool first);
};


#endif  // guard
