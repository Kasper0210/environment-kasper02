// Verilated -*- C++ -*-
// DESCRIPTION: Verilator output: Design implementation internals
// See VCounter.h for the primary calling header

#include "VCounter__pch.h"
#include "VCounter__Syms.h"
#include "VCounter___024root.h"

void VCounter___024root___ctor_var_reset(VCounter___024root* vlSelf);

VCounter___024root::VCounter___024root(VCounter__Syms* symsp, const char* v__name)
    : VerilatedModule{v__name}
    , vlSymsp{symsp}
 {
    // Reset structure values
    VCounter___024root___ctor_var_reset(this);
}

void VCounter___024root::__Vconfigure(bool first) {
    (void)first;  // Prevent unused variable warning
}

VCounter___024root::~VCounter___024root() {
}
