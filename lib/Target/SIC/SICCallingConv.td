//===-- SICCallingConv.td - Calling Conventions for SIC --*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
// This describes the calling conventions for SIC architecture.
//===----------------------------------------------------------------------===//

/// CCIfSubtarget - Match if the current subtarget has a feature F.
class CCIfSubtarget<string F, CCAction A>:
  CCIf<!strconcat("State.getTarget().getSubtarget<SICSubtarget>().", F), A>;

def RetCC_SICEABI : CallingConv<[
  // Using S and T for return beacause A may be used for calculating or loading things...
  // Perhaps not though, the return address should already be in the linkage register
  CCIfType<[i24], CCAssignToReg<[S, T]>>
  // Maybe CCAssignToStack should be used, because it uses the stack instead of registers,
  // which are quite precious on simple CISC architectures such as SIC
]>;

def RetCC_SIC : CallingConv<[
  CCDelegateTo<RetCC_SICEABI>
]>;

def CSR_O32 : CalleeSavedRegs<(add L)>;

