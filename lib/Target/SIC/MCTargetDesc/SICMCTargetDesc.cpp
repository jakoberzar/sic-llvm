//===-- SICMCTargetDesc.cpp - SIC Target Descriptions -------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides SIC specific target descriptions.
//
//===----------------------------------------------------------------------===//

#include "SICMCTargetDesc.h"
#include "InstPrinter/SICInstPrinter.h"
#include "SICMCAsmInfo.h"
#include "SICTargetStreamer.h"
#include "llvm/MC/MachineLocation.h"
#include "llvm/MC/MCELFStreamer.h"
#include "llvm/MC/MCInstrAnalysis.h"
#include "llvm/MC/MCInstPrinter.h"
#include "llvm/MC/MCInstrInfo.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define GET_INSTRINFO_MC_DESC
#include "SICGenInstrInfo.inc"

#define GET_SUBTARGETINFO_MC_DESC
#include "SICGenSubtargetInfo.inc"

#define GET_REGINFO_MC_DESC
#include "SICGenRegisterInfo.inc"
/// Select the SIC Architecture Feature for the given triple and cpu name.
/// The function will be called at command 'llvm-objdump -d' for SIC elf input.
static std::string selectSICArchFeature(const Triple &TT, StringRef CPU) {
  std::string SICArchFeature;
  if (CPU.empty() || CPU == "generic") {
    if (TT.getArch() == Triple::sic) {
      if (CPU.empty() || CPU == "sicxe") {
        SICArchFeature = "+sicxe";
      }
      else {
        if (CPU == "sicse") {
          SICArchFeature = "+sicse";
        }
      }
    }
  }
  return SICArchFeature;
}

static MCInstrInfo *createSICMCInstrInfo() {
  MCInstrInfo *X = new MCInstrInfo();
  InitSICMCInstrInfo(X); // defined in SICGenInstrInfo.inc
  return X;
}

static MCRegisterInfo *createSICMCRegisterInfo(const Triple &TT) {
  MCRegisterInfo *X = new MCRegisterInfo();
  InitSICMCRegisterInfo(X, SIC::SW); // defined in SICGenRegisterInfo.inc
  return X;
}

static MCSubtargetInfo *createSICMCSubtargetInfo(const Triple &TT,
                                                  StringRef CPU, StringRef FS) {
  std::string ArchFS = selectSICArchFeature(TT,CPU);
  if (!FS.empty()) {
    if (!ArchFS.empty())
      ArchFS = ArchFS + "," + FS.str();
    else
      ArchFS = FS;
  }
  return createSICMCSubtargetInfoImpl(TT, CPU, ArchFS);
// createSICMCSubtargetInfoImpl defined in SICGenSubtargetInfo.inc
}

static MCAsmInfo *createSICMCAsmInfo(const MCRegisterInfo &MRI,
                                      const Triple &TT) {
  MCAsmInfo *MAI = new SICMCAsmInfo(TT);

  unsigned SP = MRI.getDwarfRegNum(SIC::X, true); // SICREAL SP -> X
  MCCFIInstruction Inst = MCCFIInstruction::createDefCfa(nullptr, SP, 0);
  MAI->addInitialFrameState(Inst);

  return MAI;
}

static MCInstPrinter *createSICMCInstPrinter(const Triple &T,
                                              unsigned SyntaxVariant,
                                              const MCAsmInfo &MAI,
                                              const MCInstrInfo &MII,
                                              const MCRegisterInfo &MRI) {
  return new SICInstPrinter(MAI, MII, MRI);
}

namespace {

class SICMCInstrAnalysis : public MCInstrAnalysis {
public:
  SICMCInstrAnalysis(const MCInstrInfo *Info) : MCInstrAnalysis(Info) {}
};
}

static MCInstrAnalysis *createSICMCInstrAnalysis(const MCInstrInfo *Info) {
  return new SICMCInstrAnalysis(Info);
}


static MCStreamer *createMCStreamer(const Triple &TT, MCContext &Context,
                                    MCAsmBackend &MAB, raw_pwrite_stream &OS,
                                    MCCodeEmitter *Emitter, bool RelaxAll) {
  return createELFStreamer(Context, MAB, OS, Emitter, RelaxAll);
}

static MCTargetStreamer *createSICAsmTargetStreamer(MCStreamer &S,
                                                     formatted_raw_ostream &OS,
                                                     MCInstPrinter *InstPrint,
                                                     bool isVerboseAsm) {
  return new SICTargetAsmStreamer(S, OS);
}

extern "C" void LLVMInitializeSICTargetMC() {
  for (Target *T : {&TheSICTarget}) {
    // Register the MC asm info.
    RegisterMCAsmInfoFn X(*T, createSICMCAsmInfo);

    // Register the MC instruction info.
    TargetRegistry::RegisterMCInstrInfo(*T, createSICMCInstrInfo);

    // Register the MC register info.
    TargetRegistry::RegisterMCRegInfo(*T, createSICMCRegisterInfo);

     // Register the elf streamer.
    TargetRegistry::RegisterELFStreamer(*T, createMCStreamer);

    // Register the asm target streamer.
    TargetRegistry::RegisterAsmTargetStreamer(*T, createSICAsmTargetStreamer);

    // Register the MC subtarget info.
    TargetRegistry::RegisterMCSubtargetInfo(*T,
	                                        createSICMCSubtargetInfo);
    // Register the MC instruction analyzer.
    TargetRegistry::RegisterMCInstrAnalysis(*T, createSICMCInstrAnalysis);
    // Register the MCInstPrinter.
    TargetRegistry::RegisterMCInstPrinter(*T,
	                                      createSICMCInstPrinter);
  }

  // Register the MC Code Emitter
  TargetRegistry::RegisterMCCodeEmitter(TheSICTarget,
                                        createSICMCCodeEmitterEB);

  // Register the asm backend.
  TargetRegistry::RegisterMCAsmBackend(TheSICTarget,
                                       createSICAsmBackendEB32);
}
