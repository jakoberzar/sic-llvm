//===-- SIC.td - Describe the SIC Target Machine ---------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// Calling Conv, Instruction Descriptions
//===----------------------------------------------------------------------===//

include "SICSchedule.td"
include "SICInstrInfo.td"
include "SICCallingConv.td"

def SICInstrInfo : InstrInfo;

// Without this will have error: 'sicse' is not a recognized processor for
//  this target (ignoring processor)
//===----------------------------------------------------------------------===//
// SIC Subtarget features                                                    //
//===----------------------------------------------------------------------===//

def FeatureSICSE     : SubtargetFeature<"sicse", "SICArchVersion",
                                "SICSE", "SICSE ISA Support",
                                []>;
def FeatureSICXE    : SubtargetFeature<"sicxe", "SICArchVersion",
                               "SICXE", "SICXE ISA Support",
                                []>;

//===----------------------------------------------------------------------===//
// SIC processors supported.
//===----------------------------------------------------------------------===//

class Proc<string Name, list<SubtargetFeature> Features>
 : Processor<Name, SICGenericItineraries, Features>;

def : Proc<"sicse",  [FeatureSICSE]>;
def : Proc<"sicxe", [FeatureSICXE]>;

def SICAsmParser : AsmParser {
  let ShouldEmitMatchRegisterName = 0;
}

def SICAsmParserVariant : AsmParserVariant {
  int Variant = 0;

  // Recognize hard coded registers.
  string RegisterPrefix = "";
}

// Will generate SICGenAsmWrite.inc included by SICInstPrinter.cpp, contents
//  as follows,
// void SICInstPrinter::printInstruction(const MCInst *MI, raw_ostream &O) {...}
// const char *SICInstPrinter::getRegisterName(unsigned RegNo) {...}
def SIC : Target {
// def SICInstrInfo : InstrInfo as before.
  let InstructionSet = SICInstrInfo;
  let AssemblyParsers = [SICAsmParser];
  let AssemblyParserVariants = [SICAsmParserVariant];
}
