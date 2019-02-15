//===-- SICAsmPrinter.cpp - SIC LLVM Assembly Printer -------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains a printer that converts from our internal representation
// of machine-dependent LLVM code to SIC assembly language.
//
//===----------------------------------------------------------------------===//

#include "SICAsmPrinter.h"
#include "InstPrinter/SICInstPrinter.h"
#include "MCTargetDesc/SICBaseInfo.h"
#include "SIC.h"
#include "SICInstrInfo.h"
#include "llvm/ADT/SmallString.h"
#include "llvm/ADT/StringExtras.h"
#include "llvm/ADT/Twine.h"
#include "llvm/CodeGen/MachineConstantPool.h"
#include "llvm/CodeGen/MachineFunctionPass.h"
#include "llvm/CodeGen/MachineFrameInfo.h"
#include "llvm/CodeGen/MachineInstr.h"
#include "llvm/CodeGen/MachineMemOperand.h"
#include "llvm/IR/BasicBlock.h"
#include "llvm/IR/Instructions.h"
#include "llvm/IR/Mangler.h"
#include "llvm/MC/MCAsmInfo.h"
#include "llvm/MC/MCInst.h"
#include "llvm/MC/MCStreamer.h"
#include "llvm/MC/MCSymbol.h"
#include "llvm/Support/raw_ostream.h"
#include "llvm/Support/TargetRegistry.h"
#include "llvm/Target/TargetLoweringObjectFile.h"
#include "llvm/Target/TargetOptions.h"

using namespace llvm;

#define DEBUG_TYPE "sic-asm-printer"

bool SICAsmPrinter::runOnMachineFunction(MachineFunction &MF) {
  SICFI = MF.getInfo<SICFunctionInfo>();
  AsmPrinter::runOnMachineFunction(MF);
  return true;
}

bool SICAsmPrinter::lowerOperand(const MachineOperand &MO, MCOperand &MCOp) {
  MCOp = MCInstLowering.LowerOperand(MO);
  return MCOp.isValid();
}

#include "SICGenMCPseudoLowering.inc"

//- EmitInstruction() must exists or will have run time error.
void SICAsmPrinter::EmitInstruction(const MachineInstr *MI) {
  if (MI->isDebugValue()) {
    SmallString<128> Str;
    raw_svector_ostream OS(Str);

    PrintDebugValueComment(MI, OS);
    return;
  }

  //  Print out both ordinary instruction and boudle instruction
  MachineBasicBlock::const_instr_iterator I = MI->getIterator();
  MachineBasicBlock::const_instr_iterator E = MI->getParent()->instr_end();

  do {
    // Do any auto-generated pseudo lowerings.
    if (emitPseudoExpansionLowering(*OutStreamer, &*I))
      continue;

    if (I->isPseudo())
      llvm_unreachable("Pseudo opcode found in EmitInstruction()");

    MCInst TmpInst0;
    MCInstLowering.Lower(&*I, TmpInst0);
    OutStreamer->EmitInstruction(TmpInst0, getSubtargetInfo());
  } while ((++I != E) && I->isInsideBundle()); // Delay slot check
}


// Print a 32 bit hex number with all numbers.
void SICAsmPrinter::printHex32(unsigned Value, raw_ostream &O) {
  O << "0x";
  for (int i = 7; i >= 0; i--)
    O.write_hex((Value & (0xF << (i*4))) >> (i*4));
}


/// Emit Set directives.
const char *SICAsmPrinter::getCurrentABIString() const {
  switch (static_cast<SICTargetMachine &>(TM).getABI().GetEnumValue()) {
  case SICABIInfo::ABI::O32:  return "abiO32";
  case SICABIInfo::ABI::S32:  return "abiS32";
  default: llvm_unreachable("Unknown SIC ABI");
  }
}

//	main:
void SICAsmPrinter::EmitFunctionEntryLabel() {
  OutStreamer->EmitLabel(CurrentFnSym);
}


/// EmitFunctionBodyStart - Targets can override this to emit stuff before
/// the first basic block in the function.
void SICAsmPrinter::EmitFunctionBodyStart() {
  MCInstLowering.Initialize(&MF->getContext());
  return;
}

//->	.end	main
/// EmitFunctionBodyEnd - Targets can override this to emit stuff after
/// the last basic block in the function.
void SICAsmPrinter::EmitFunctionBodyEnd() {
  // There are instruction for this macros, but they must
  // always be at the function end, and we can't emit and
  // break with BB logic.
  if (OutStreamer->hasRawTextSupport()) {
    // SIC - No need for end...
    // OutStreamer->EmitRawText("\t.end\t" + Twine(CurrentFnSym->getName()));
  }
}

void SICAsmPrinter::EmitStartOfAsmFile(Module &M) {
   // TODO - This is optional, give the user a option to enable it
  if (OutStreamer->hasRawTextSupport()) {
    OutStreamer->EmitRawText("\t+LDX\t#0xFFFFC");
    OutStreamer->EmitRawText("\tJSUB\tmain");
    // OutStreamer->EmitRawText("\tRMO\tS, A");
    // OutStreamer->EmitRawText("\tWD\t#1");
    OutStreamer->EmitRawText("halt\tJ\thalt");
  }
}

// Print the required MEM registers.
void SICAsmPrinter::EmitEndOfAsmFile(Module &M) {
  if (OutStreamer->hasRawTextSupport()) {
    OutStreamer->EmitRawText("MEMREG\tRESW\t1");
  }
}

// Done to prevent the effects of func end label.
void SICAsmPrinter::EmitJumpTableInfo() {
  if (OutStreamer->hasRawTextSupport()) {
    OutStreamer->EmitRawText("\tEQU\t*");
    OutStreamer->EmitRawText("\tLTORG\t");
  }
}

void SICAsmPrinter::PrintDebugValueComment(const MachineInstr *MI,
                                           raw_ostream &OS) {
  // TODO: implement
  OS << "PrintDebugValueComment()";
}

// Force static initialization.
extern "C" void LLVMInitializeSICAsmPrinter() {
  RegisterAsmPrinter<SICAsmPrinter> X(TheSICTarget);
}
