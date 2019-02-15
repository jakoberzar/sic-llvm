//===-- SICTargetMachine.cpp - Define TargetMachine for SIC -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// Implements the info about SIC target spec.
//
//===----------------------------------------------------------------------===//

#include "SICTargetMachine.h"
#include "SIC.h"
#include "SICISelDAGToDAG.h"
#include "SICSubtarget.h"
#include "SICTargetObjectFile.h"
#include "llvm/IR/LegacyPassManager.h"
#include "llvm/CodeGen/Passes.h"
#include "llvm/CodeGen/TargetPassConfig.h"
#include "llvm/Support/TargetRegistry.h"
using namespace llvm;

#define DEBUG_TYPE "sic"

// Register the target.
extern "C" void LLVMInitializeSICTarget() {
  RegisterTargetMachine<SICTargetMachine> X(TheSICTarget);
}

static std::string computeDataLayout(const Triple &TT, StringRef CPU,
                                     const TargetOptions &Options,
                                     bool isLittle) {
  std::string Ret = "";
  // There are both little and big endian sic.
  if (isLittle)
    Ret += "e";
  else
    Ret += "E";

  // Ret += "-m:m";

  // Pointers are 32 bit on some ABIs.
  Ret += "-p:24:32";

  // 8, 16 and 24 bit integers only need to have natural alignment, but try to
  // align them to 32 bits.
  Ret += "-i8:8:32-i16:16:32-i24:32";

  // 24 bit registers are always available and the stack is at least 32 bit
  // aligned.
  Ret += "-n24-S32";

  return Ret;
}

static Reloc::Model getEffectiveRelocModel(CodeModel::Model CM,
                                           Optional<Reloc::Model> RM) {
  if (!RM.hasValue() || CM == CodeModel::JITDefault)
    return Reloc::Static;
  return *RM;
}

// DataLayout --> Big-endian, 32-bit pointer/ABI/alignment
// The stack is always 8 byte aligned
// On function prologue, the stack is created by decrementing
// its pointer. Once decremented, all references are done with positive
// offset from the stack/frame pointer, using StackGrowsUp enables
// an easier handling.
// Using CodeModel::Large enables different CALL behavior.
SICTargetMachine::SICTargetMachine(const Target &T, const Triple &TT,
                                     StringRef CPU, StringRef FS,
                                     const TargetOptions &Options,
                                     Optional<Reloc::Model> RM,
                                     CodeModel::Model CM, CodeGenOpt::Level OL)
  //- Default is big endian
    : LLVMTargetMachine(T, computeDataLayout(TT, CPU, Options, false), TT,
                        CPU, FS, Options, getEffectiveRelocModel(CM, RM), CM,
                        OL),
      isLittle(false), TLOF(make_unique<SICTargetObjectFile>()),
      ABI(SICABIInfo::computeTargetABI()),
      DefaultSubtarget(TT, CPU, FS, false, *this) {
  // initAsmInfo will display features by llc -march=sic -mcpu=help on 3.7 but
  // not on 3.6
  initAsmInfo();
}

SICTargetMachine::~SICTargetMachine() {}

const SICSubtarget *
SICTargetMachine::getSubtargetImpl(const Function &F) const {
  Attribute CPUAttr = F.getFnAttribute("target-cpu");
  Attribute FSAttr = F.getFnAttribute("target-features");

  std::string CPU = !CPUAttr.hasAttribute(Attribute::None)
                        ? CPUAttr.getValueAsString().str()
                        : TargetCPU;
  std::string FS = !FSAttr.hasAttribute(Attribute::None)
                       ? FSAttr.getValueAsString().str()
                       : TargetFS;

  auto &I = SubtargetMap[CPU + FS];
  if (!I) {
    // This needs to be done before we create a new subtarget since any
    // creation will depend on the TM and the code generation flags on the
    // function that reside in TargetOptions.
    resetTargetOptions(F);
    I = llvm::make_unique<SICSubtarget>(TargetTriple, CPU, FS, isLittle,
                                         *this);
  }
  return I.get();
}

namespace {
/// SIC Code Generator Pass Configuration Options.
class SICPassConfig : public TargetPassConfig {
public:
  SICPassConfig(SICTargetMachine *TM, PassManagerBase &PM)
    : TargetPassConfig(TM, PM) {}

  SICTargetMachine &getSICTargetMachine() const {
    return getTM<SICTargetMachine>();
  }

  const SICSubtarget &getSICSubtarget() const {
    return *getSICTargetMachine().getSubtargetImpl();
  }

  bool addInstSelector() override;

  void addPreEmitPass() override;
};
} // namespace

TargetPassConfig *SICTargetMachine::createPassConfig(PassManagerBase &PM) {
  return new SICPassConfig(this, PM);
}

// Install an instruction selector pass using
// the ISelDag to gen SIC code.
bool SICPassConfig::addInstSelector() {
  addPass(createSICISelDag(getSICTargetMachine(), getOptLevel()));
  return false;
}

// Implemented by targets that want to run passes immediately before
// machine code is emitted. return true if -print-machineinstrs should
// print out the code after the passes.
void SICPassConfig::addPreEmitPass() {
  SICTargetMachine &TM = getSICTargetMachine();

  addPass(createSICDelJmpPass(TM));

  return;
}
