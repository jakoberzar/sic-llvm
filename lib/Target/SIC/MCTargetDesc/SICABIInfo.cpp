//===---- SICABIInfo.cpp - Information about SIC ABI's ------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "SICABIInfo.h"
#include "SICRegisterInfo.h"
#include "llvm/ADT/StringRef.h"
#include "llvm/ADT/StringSwitch.h"
#include "llvm/MC/MCTargetOptions.h"
#include "llvm/Support/CommandLine.h"

using namespace llvm;

// static cl::opt<bool>
// EnableSICS32Calls("sic-s32-calls", cl::Hidden,
//                     cl::desc("SIC S32 call: use stack only to pass arguments.\
//                     "), cl::init(true));

namespace {
static const MCPhysReg O32IntRegs[2] = {SIC::S, SIC::T}; // Not passing by registers yet
static const MCPhysReg S32IntRegs = {};
}

const ArrayRef<MCPhysReg> SICABIInfo::GetByValArgRegs() const {
  if (IsO32())
    return makeArrayRef(O32IntRegs);
  if (IsS32())
    return makeArrayRef(S32IntRegs);
  llvm_unreachable("Unhandled ABI");
}

const ArrayRef<MCPhysReg> SICABIInfo::GetVarArgRegs() const {
  if (IsO32())
    return makeArrayRef(O32IntRegs);
  if (IsS32())
    return makeArrayRef(S32IntRegs);
  llvm_unreachable("Unhandled ABI");
}

unsigned SICABIInfo::GetCalleeAllocdArgSizeInBytes(CallingConv::ID CC) const {
  if (IsO32())
    return CC != 0;
  if (IsS32())
    return 0;
  llvm_unreachable("Unhandled ABI");
}

SICABIInfo SICABIInfo::computeTargetABI() {
  SICABIInfo abi(ABI::Unknown);

  // We currently only use S32 abi to pass all parameters via stack.
  // We could expand to O32 and send two via registers in the future.
  abi = ABI::S32;

  // if (EnableSICS32Calls)
  //   abi = ABI::S32;
  // else
  //   abi = ABI::O32;

  // Assert exactly one ABI was chosen.
  assert(abi.ThisABI != ABI::Unknown);

  return abi;
}

unsigned SICABIInfo::GetStackPtr() const {
  return SIC::X; // SIC uses SP -> X
}

unsigned SICABIInfo::GetFramePtr() const {
  return SIC::X; // SIC uses FP -> X
}

unsigned SICABIInfo::GetEhDataReg(unsigned I) const {
  static const unsigned EhDataReg[] = {
    SIC::S, SIC::T
  };

  return EhDataReg[I];
}

int SICABIInfo::EhDataRegSize() const {
  if (ThisABI == ABI::S32)
    return 0;
  else
    return 2;
}
