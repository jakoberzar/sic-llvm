//=== SICInstPrinter.h - Convert SIC MCInst to assembly syntax -*- C++ -*-==//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This class prints a SIC MCInst to a .s file.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SIC_INSTPRINTER_SICINSTPRINTER_H
#define LLVM_LIB_TARGET_SIC_INSTPRINTER_SICINSTPRINTER_H

#include "llvm/MC/MCInstPrinter.h"

namespace llvm {
// These enumeration declarations were orignally in SICInstrInfo.h but
// had to be moved here to avoid circular dependencies between
// LLVMSICCodeGen and LLVMSICAsmPrinter.

class TargetMachine;

class SICInstPrinter : public MCInstPrinter {
public:
  SICInstPrinter(const MCAsmInfo &MAI, const MCInstrInfo &MII,
                  const MCRegisterInfo &MRI)
    : MCInstPrinter(MAI, MII, MRI) {}

  // Autogenerated by tblgen.
  void printInstruction(const MCInst *MI, raw_ostream &O);
  static const char *getRegisterName(unsigned RegNo);

  void printRegName(raw_ostream &OS, unsigned RegNo) const override;
  void printInst(const MCInst *MI, raw_ostream &O, StringRef Annot,
                 const MCSubtargetInfo &STI) override;

  bool printAliasInstr(const MCInst *MI, raw_ostream &OS);
  void printCustomAliasOperand(const MCInst *MI, unsigned OpIdx,
                               unsigned PrintMethodIdx, raw_ostream &O);

private:
  void printOperand(const MCInst *MI, unsigned OpNo, raw_ostream &O);
  void printUnsignedImm(const MCInst *MI, int opNum, raw_ostream &O);
  void printMemOperand(const MCInst *MI, int opNum, raw_ostream &O);
  void printMemOperandEA(const MCInst *MI, int opNum, raw_ostream &O);
  void printMemOperandSICEA(const MCInst *MI, int opNum, raw_ostream &O);
};
} // end namespace llvm

#endif
