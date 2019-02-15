//===-- SICMachineFunctionInfo.cpp - Private data used for SIC ----------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#include "SICMachineFunction.h"
#include "MCTargetDesc/SICBaseInfo.h"
#include "SICInstrInfo.h"
#include "SICSubtarget.h"
#include "llvm/IR/Function.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"

using namespace llvm;

SICFunctionInfo::~SICFunctionInfo() {}

bool SICFunctionInfo::globalBaseRegSet() const {
  return GlobalBaseReg;
}

unsigned SICFunctionInfo::getGlobalBaseReg() {
  return GlobalBaseReg = SIC::B; // SIC GP -> B
}

void SICFunctionInfo::createEhDataRegsFI() {
  for (int I = 0; I < 2; ++I) {
    const TargetRegisterClass *RC = &SIC::CPURegsRegClass;

    EhDataRegFI[I] = MF.getFrameInfo()->CreateStackObject(RC->getSize(),
        RC->getAlignment(), false);
  }
}

MachinePointerInfo SICFunctionInfo::callPtrInfo(const char *ES) {
  return MachinePointerInfo(MF.getPSVManager().getExternalSymbolCallEntry(ES));
}

MachinePointerInfo SICFunctionInfo::callPtrInfo(const GlobalValue *GV) {
  return MachinePointerInfo(MF.getPSVManager().getGlobalValueCallEntry(GV));
}

void SICFunctionInfo::anchor() { }
