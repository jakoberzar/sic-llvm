//===-- SICTargetMachine.h - Define TargetMachine for SIC -----*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file declares the SIC specific subclass of TargetMachine.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SIC_SICTARGETMACHINE_H
#define LLVM_LIB_TARGET_SIC_SICTARGETMACHINE_H

#include "MCTargetDesc/SICABIInfo.h"
#include "SICSubtarget.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/Target/TargetFrameLowering.h"
#include "llvm/Target/TargetMachine.h"

namespace llvm {
class formatted_raw_ostream;
class SICRegisterInfo;

class SICTargetMachine : public LLVMTargetMachine {
  bool isLittle;
  std::unique_ptr<TargetLoweringObjectFile> TLOF;
  // Selected ABI
  SICABIInfo ABI;
  SICSubtarget DefaultSubtarget;

  mutable StringMap<std::unique_ptr<SICSubtarget>> SubtargetMap;
public:
  SICTargetMachine(const Target &T, const Triple &TT, StringRef CPU,
                    StringRef FS, const TargetOptions &Options,
                    Optional<Reloc::Model> RM, CodeModel::Model CM,
                    CodeGenOpt::Level OL);
  ~SICTargetMachine() override;

  const SICSubtarget *getSubtargetImpl() const {
    return &DefaultSubtarget;
  }

  const SICSubtarget *getSubtargetImpl(const Function &F) const override;

  // Pass Pipeline Configuration
  TargetPassConfig *createPassConfig(PassManagerBase &PM) override;

  TargetLoweringObjectFile *getObjFileLowering() const override {
    return TLOF.get();
  }
  bool isLittleEndian() const { return isLittle; }
  const SICABIInfo &getABI() const { return ABI; }
};

} // End llvm namespace

#endif
