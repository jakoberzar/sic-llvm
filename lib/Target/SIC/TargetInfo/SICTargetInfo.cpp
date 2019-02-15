//===-- SICTargetInfo.cpp - SIC Target Implementation -------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "SIC.h"
#include "llvm/IR/Module.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

Target llvm::TheSICTarget;

extern "C" void LLVMInitializeSICTargetInfo() {
  RegisterTarget<Triple::sic,
        /*HasJIT=*/false> X(TheSICTarget, "sic", "SIC");
}
