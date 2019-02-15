//===-- SICInstrFormats.td - SIC Instruction Formats -----*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Describe SIC instructions format
//
//  CPU INSTRUCTION FORMATS
//
//  opcode  - operation code.
//  r1      - src reg
//  r2      - dst reg, when used two registers
//  offset  - offset from x, b, or PC
//  address - complete address
//
//===----------------------------------------------------------------------===//

// Format specifies the encoding used by the instruction.  This is part of the
// ad-hoc solution used to emit machine instruction encodings by our machine
// code emitter.
class Format<bits<4> val> {
  bits<4> Value = val;
}

def Pseudo: Format<0>;
def Frm1  : Format<1>;
def Frm2  : Format<2>;
def Frm3  : Format<3>;
def Frm4  : Format<4>;

// Generic SIC Format
class SICInst<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
               InstrItinClass itin, Format f>: Instruction
{
  field bits<32> Inst; // Perhaps this should be format dependant?
  Format Form = f;

  let Namespace = "SIC";

  let Size = Form.Value; // Warning: this sets the Size of SicPseudo to 0!

  bits<6> Opcode = op{7-2};

  let OutOperandList = outs;
  let InOperandList  = ins;

  let AsmString   = asmstr;
  let Pattern     = pattern;
  let Itinerary   = itin;

  //
  // Attributes specific to SIC instructions...
  //
  bits<4> FormBits = Form.Value;

  // TSFlags layout should be kept in sync with SICInstrInfo.h.
  let TSFlags{3-0}   = FormBits;

  let DecoderNamespace = "SIC";

  field bits<32> SoftFail = 0;
}

// SIC Pseudo Instructions Format
class SICPseudo<dag outs, dag ins, string asmstr, list<dag> pattern>:
      SICInst<0, outs, ins, asmstr, pattern, IIPseudo, Pseudo> {
  let isCodeGenOnly = 1;
  let isPseudo = 1;
}

// SIC32 Pseudo Instruction Format
class PseudoSE<dag outs, dag ins, list<dag> pattern,
               InstrItinClass itin = IIPseudo> :
  SICPseudo<outs, ins, "", pattern> {
}


//===----------------------------------------------------------------------===//
// Format 1 instruction class in SIC : <|opcode|>
//===----------------------------------------------------------------------===//

class F1<bits<8> op, dag outs, dag ins, string asmstr,
         list<dag> pattern, InstrItinClass itin>:
      SICInst<op, outs, ins, asmstr, pattern, itin, Frm1>
{
  let Inst{7-0} = op;
}

//===----------------------------------------------------------------------===//
// Format 2 instruction class in SIC : <|opcode|r1|r2|>
//===----------------------------------------------------------------------===//

class F2<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
         InstrItinClass itin>: SICInst<op, outs, ins, asmstr, pattern, itin, Frm2>
{
  bits<4> r1;
  bits<4> r2;

  let Inst{15-8} = op;
  let Inst{7-4}  = r1;
  let Inst{3-0}  = r2;
}


//===----------------------------------------------------------------------===//
// Format 3/4 instruction class in SIC : <|opcode|n|i|x|b|p|e|(offset/address)|>
//===----------------------------------------------------------------------===//
class AddressUseModesBits<bits<2> mode> {
  bits<2> Mode = mode;
  bit Indirect = mode{1};
  bit Immediate = mode{0};
}
// def SICFormatAddressUse: AddressUseModesBits<0>;
def ImmediateAddressUse: AddressUseModesBits<1>;
def IndirectAddressUse:  AddressUseModesBits<2>;
def SimpleAddressUse:    AddressUseModesBits<3>;

class AddressingModesBits<bits<2> mode> {
  bits<2> Mode = mode;
  bit Base = mode{1};
  bit PC = mode{0};
}
def DirectAddressing:     AddressingModesBits<0>;
def PCRelativeAddressing: AddressingModesBits<1>;
def BaseAddressing:       AddressingModesBits<2>;

class F34<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
         InstrItinClass itin, Format frm>: SICInst<op, outs, ins, asmstr, pattern, itin, frm>
{
  AddressUseModesBits AddressUseMode = SimpleAddressUse;
  AddressingModesBits AddressingMode = DirectAddressing;
  bit IndexedAddressing;
  bit ExtendedInstruction;
}

//===----------------------------------------------------------------------===//
// Format 3 instruction class in SIC : <|opcode|n|i|x|b|p|e|offset|>
//===----------------------------------------------------------------------===//
class F3<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
         InstrItinClass itin>: F34<op, outs, ins, asmstr, pattern, itin, Frm3>
{
  bits<12> offset;
  let ExtendedInstruction = 0;

  let Inst{23-18} = Opcode;
  let Inst{17} = AddressUseMode.Indirect;
  let Inst{16} = AddressUseMode.Immediate;
  let Inst{15} = IndexedAddressing;
  let Inst{14} = AddressingMode.Base;
  let Inst{13} = AddressingMode.PC;
  let Inst{12} = ExtendedInstruction;
  let Inst{11-0} = offset;
}


//===----------------------------------------------------------------------===//
// Format 4 instruction class in SIC : <|opcode|n|i|x|b|p|e|address|>
//===----------------------------------------------------------------------===//
class F4<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
         InstrItinClass itin>: F34<op, outs, ins, !strconcat("+", asmstr), pattern, itin, Frm4>
{
  bits<20> address;
  let ExtendedInstruction = 1;

  let Inst{31-26} = Opcode;
  let Inst{25} = AddressUseMode.Indirect;
  let Inst{24} = AddressUseMode.Immediate;
  let Inst{23} = IndexedAddressing;
  let Inst{22} = AddressingMode.Base;
  let Inst{21} = AddressingMode.PC;
  let Inst{20} = ExtendedInstruction;
  let Inst{19-0} = address;
}
