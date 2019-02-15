//===-- SIC.h - Top-level interface for SIC representation ----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the entry points for global functions defined in
// the LLVM SIC back-end.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SIC_SIC_H
#define LLVM_LIB_TARGET_SIC_SIC_H

#include "MCTargetDesc/SICMCTargetDesc.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
  class SICTargetMachine;
  class FunctionPass;

  FunctionPass *createSICDelJmpPass(SICTargetMachine &TM);

} // end namespace llvm;

#endif
