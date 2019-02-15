//===-- SICSubtarget.cpp - SIC Subtarget Information --------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file implements the SIC specific subclass of TargetSubtargetInfo.
//
//===----------------------------------------------------------------------===//

#include "SICSubtarget.h"
#include "SICMachineFunction.h"
#include "SIC.h"
#include "SICRegisterInfo.h"

#include "SICTargetMachine.h"
#include "llvm/IR/Attributes.h"
#include "llvm/IR/Function.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define DEBUG_TYPE "sic-subtarget"

#define GET_SUBTARGETINFO_TARGET_DESC
#define GET_SUBTARGETINFO_CTOR
#include "SICGenSubtargetInfo.inc"

void SICSubtarget::anchor() { }

SICSubtarget::SICSubtarget(const Triple &TT, const std::string &CPU,
                             const std::string &FS, bool little,
                             const SICTargetMachine &_TM) :
  // SICGenSubtargetInfo will display features by llc -march=sic -mcpu=help
  SICGenSubtargetInfo(TT, CPU, FS),
  IsLittle(little), TM(_TM), TargetTriple(TT), TSInfo(),
      InstrInfo(
          SICInstrInfo::create(initializeSubtargetDependencies(CPU, FS, TM))),
      FrameLowering(SICFrameLowering::create(*this)),
      TLInfo(SICTargetLowering::create(TM, *this)) {
}

bool SICSubtarget::isPositionIndependent() const {
  return TM.isPositionIndependent();
}

SICSubtarget &
SICSubtarget::initializeSubtargetDependencies(StringRef CPU, StringRef FS,
                                               const TargetMachine &TM) {
  if (TargetTriple.getArch() == Triple::sic) {
    if (CPU.empty() || CPU == "generic") {
      CPU = "sicxe";
    }
    else if (CPU == "help") {
      CPU = "";
      return *this;
    }
    else if (CPU != "sicse" && CPU != "sicxe") {
      CPU = "sicxe";
    }
  }
  else {
    errs() << "!!!Error, TargetTriple.getArch() = " << TargetTriple.getArch()
           <<  "CPU = " << CPU << "\n";
    exit(0);
  }

  if (CPU == "sicse")
    SICArchVersion = SICSE;
  else if (CPU == "sicxe")
    SICArchVersion = SICXE;

  // Parse features string.
  ParseSubtargetFeatures(CPU, FS);
  // Initialize scheduling itinerary for the specified CPU.
  InstrItins = getInstrItineraryForCPU(CPU);

  return *this;
}

bool SICSubtarget::abiUsesSoftFloat() const {
//  return TM->Options.UseSoftFloat;
  return true;
}

const SICABIInfo &SICSubtarget::getABI() const { return TM.getABI(); }
