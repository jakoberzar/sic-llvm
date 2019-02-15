//===- SICInstrInfo.td - Target Description for SIC Target -*- tablegen -*-=//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the SIC implementation of the TargetInstrInfo class.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// SIC profiles and nodes
//===----------------------------------------------------------------------===//

def SDT_SICRet          : SDTypeProfile<0, 1, [SDTCisInt<0>]>;
def SDT_SICDivRem       : SDTypeProfile<0, 2,
                                         [SDTCisInt<0>,
                                          SDTCisSameAs<0, 1>]>;

def SDT_SICJmpLink      : SDTypeProfile<0, 1, [SDTCisVT<0, iPTR>]>;

def SDT_SICCallSeqStart : SDCallSeqStart<[SDTCisVT<0, i24>]>;
def SDT_SICCallSeqEnd   : SDCallSeqEnd<[SDTCisVT<0, i24>, SDTCisVT<1, i24>]>;


// Call
def SICJmpLink : SDNode<"SICISD::JmpLink",SDT_SICJmpLink,
                         [SDNPHasChain, SDNPOutGlue, SDNPOptInGlue,
                          SDNPVariadic]>;

// Tail call
def SICTailCall : SDNode<"SICISD::TailCall", SDT_SICJmpLink,
                          [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// Hi and Lo nodes are used to handle global addresses. Used on
// SICISelLowering to lower stuff like GlobalAddress, ExternalSymbol
// static model. (nothing to do with SIC Registers Hi and Lo)
def SICHi    : SDNode<"SICISD::Hi", SDTIntUnaryOp>;
def SICLo    : SDNode<"SICISD::Lo", SDTIntUnaryOp>;
def SICGPRel : SDNode<"SICISD::GPRel", SDTIntUnaryOp>;
// SIC - Adding global node
def SICGlob  : SDNode<"SICISD::Glob", SDTIntUnaryOp>;

// Return
def SICRet : SDNode<"SICISD::Ret", SDTNone,
                     [SDNPHasChain, SDNPOptInGlue, SDNPVariadic]>;

// These are target-independent nodes, but have target-specific formats.
def callseq_start : SDNode<"ISD::CALLSEQ_START", SDT_SICCallSeqStart,
                           [SDNPHasChain, SDNPOutGlue]>;
def callseq_end   : SDNode<"ISD::CALLSEQ_END", SDT_SICCallSeqEnd,
                           [SDNPHasChain, SDNPOptInGlue, SDNPOutGlue]>;

// DivRem(u) nodes
def SICDivRem    : SDNode<"SICISD::DivRem", SDT_SICDivRem,
                           [SDNPOutGlue]>;
def SICDivRemU   : SDNode<"SICISD::DivRemU", SDT_SICDivRem,
                           [SDNPOutGlue]>;

def SICWrapper    : SDNode<"SICISD::Wrapper", SDTIntBinOp>;

//===----------------------------------------------------------------------===//
// SIC Instruction Predicate Definitions.
//===----------------------------------------------------------------------===//

def RelocPIC    :     Predicate<"TM.getRelocationModel() == Reloc::PIC_">;

class SICInstAlias<string Asm, dag Result, bit Emit = 0b1> :
  InstAlias<Asm, Result, Emit>;

class IsTailCall {
  bit isCall = 1;
  bit isTerminator = 1;
  bit isReturn = 1;
  bit isBarrier = 1;
  bit hasExtraSrcRegAllocReq = 1;
  bit isCodeGenOnly = 1;
}

//===----------------------------------------------------------------------===//
// Instruction format superclass
//===----------------------------------------------------------------------===//

include "SICInstrFormats.td"

//===----------------------------------------------------------------------===//
// SIC Operand, Complex Patterns and Transformations Definitions.
//===----------------------------------------------------------------------===//
// Instruction operand types

// BEQ, BNE
def brtarget16    : Operand<OtherVT> {
  let EncoderMethod = "getBranch16TargetOpValue";
  let OperandType = "OPERAND_PCREL";
  let DecoderMethod = "DecodeBranch16Target";
}

// JEQ, JNE, ...
def brtarget24    : Operand<OtherVT> {
  let EncoderMethod = "getBranch24TargetOpValue";
  let OperandType = "OPERAND_PCREL";
  let DecoderMethod = "DecodeBranch24Target";
}

// JMP
def jmptarget    : Operand<OtherVT> {
  let EncoderMethod = "getJumpTargetOpValue";
  let OperandType = "OPERAND_PCREL";
}

def calltarget  : Operand<iPTR> {
  let EncoderMethod = "getJumpTargetOpValue";
}

// Signed Operand
def simm16      : Operand<i24> {
  let DecoderMethod= "DecodeSimm16";
}
def simm24      : Operand<i24> {
  let DecoderMethod= "DecodeSimm24";
}

def shamt       : Operand<i24>;

// Unsigned Operand
def uimm16      : Operand<i24> {
  let PrintMethod = "printUnsignedImm";
}
def uimm12      : Operand<i24> {
  let PrintMethod = "printUnsignedImm";
}
def uimm20      : Operand<i24>;

// Address operand
def mem : Operand<iPTR> {
  let PrintMethod = "printMemOperand";
  let MIOperandInfo = (ops CPURegs, simm16);
  let EncoderMethod = "getMemEncoding";
}

def mem_ea : Operand<iPTR> {
  let PrintMethod = "printMemOperandEA";
  let MIOperandInfo = (ops CPURegs, simm16);
  let EncoderMethod = "getMemEncoding";
}

def mem_sicea : Operand<iPTR> {
  let PrintMethod = "printMemOperandSICEA";
  let MIOperandInfo = (ops CPURegs, simm16);
  let EncoderMethod = "getMemEncoding";
}

def mem_glob : Operand<iPTR> {
  // let PrintMethod = "printMemGlobOperand";
  let MIOperandInfo = (ops tglobaladdr);
}

// Transformation Function - get the lower 16 bits.
def LO16 : SDNodeXForm<imm, [{
  return getImm(N, N->getZExtValue() & 0xffff);
}]>;

// Transformation Function - get the higher 16 bits.
def HI16 : SDNodeXForm<imm, [{
  return getImm(N, (N->getZExtValue() >> 16) & 0xffff);
}]>;

def SHLMask : SDNodeXForm<imm, [{
  return getImm(N, (0xFFFFFF - ((1 << N->getZExtValue()) - 1)));
}]>;

def SRLMask : SDNodeXForm<imm, [{
  return getImm(N, ((1 << (24 - N->getZExtValue()))  - 1));
}]>;

def Sub24Imm : SDNodeXForm<imm, [{
  return getImm(N, 24 - N->getZExtValue());
}]>;


// Node immediate fits as 16-bit sign extended on target immediate.
// e.g. addi, andi
def immSExt16  : PatLeaf<(imm), [{ return isInt<16>(N->getSExtValue()); }]>;
def immSExt24  : PatLeaf<(imm), [{ return isInt<24>(N->getSExtValue()); }]>;

// Node immediate fits as 16-bit zero extended on target immediate.
// The LO16 param means that only the lower 16 bits of the node
// immediate are caught.
// e.g. addiu, sltiu
def immZExt16  : PatLeaf<(imm), [{
  if (N->getValueType(0) == MVT::i24)
    return (uint32_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
  else
    return (uint64_t)N->getZExtValue() == (unsigned short)N->getZExtValue();
}], LO16>;

// Immediate can be loaded with LUi (32-bit int with lower 16-bit cleared).
def immLow16Zero : PatLeaf<(imm), [{
  int64_t Val = N->getSExtValue();
  return isInt<32>(Val) && !(Val & 0xffff);
}]>;

// shamt field must fit in 5 bits.
def immZExt5 : ImmLeaf<i24, [{return Imm == (Imm & 0x1f);}]>;
def immZExt12  : PatLeaf<(imm), [{ return isUInt<12>(N->getZExtValue()); }]>;
def immZExt20  : PatLeaf<(imm), [{ return isUInt<20>(N->getZExtValue()); }]>;

// If immediate is in range
def immIn12To16 : PatLeaf<(imm), [{
  return N->getZExtValue() >= 12 && N->getZExtValue() <= 16;
}]>;
def immIn4To11 : PatLeaf<(imm), [{
  return N->getZExtValue() >= 4 && N->getZExtValue() <= 11;
}]>;
def immIn1To4 : PatLeaf<(imm), [{
  return N->getZExtValue() >= 1 && N->getZExtValue() <= 4;
}]>;

// SIC Address Mode! SDNode frameindex could possibily be a match
// since load and store instructions from stack used it.
def addr :
  ComplexPattern<iPTR, 2, "SelectAddr", [frameindex], [SDNPWantParent]>;

//===----------------------------------------------------------------------===//
// Pattern fragment for load/store
//===----------------------------------------------------------------------===//

class AlignedLoad<PatFrag Node> :
  PatFrag<(ops node:$ptr), (Node node:$ptr), [{
  LoadSDNode *LD = cast<LoadSDNode>(N);
  return LD->getMemoryVT().getSizeInBits()/8 <= LD->getAlignment();
}]>;

class AlignedStore<PatFrag Node> :
  PatFrag<(ops node:$val, node:$ptr), (Node node:$val, node:$ptr), [{
  StoreSDNode *SD = cast<StoreSDNode>(N);
  return SD->getMemoryVT().getSizeInBits()/8 <= SD->getAlignment();
}]>;

// Load/Store PatFrags.
def sextloadi16_a   : AlignedLoad<sextloadi16>;
def zextloadi16_a   : AlignedLoad<zextloadi16>;
def extloadi16_a    : AlignedLoad<extloadi16>;
def load_a          : AlignedLoad<load>;
def truncstorei16_a : AlignedStore<truncstorei16>;
def store_a         : AlignedStore<store>;

//===----------------------------------------------------------------------===//
// Instructions specific format
//===----------------------------------------------------------------------===//

// Arithmetic and logical instructions with register & register operands.
// ADDR, SUBR, MULR, DIVR, RMO, (COMPR??? - probs not)
class ArithLogicR<bits<8> op, string instr_asm, SDNode OpNode,
                  InstrItinClass itin, RegisterClass RC, RegisterClass RD, bit isComm = 0>:
  F2<op, (outs GPROut:$r3), (ins RC:$r2, RD:$r1),
     !strconcat(instr_asm, "\t$r1, $r2"),
     [(set GPROut:$r3, (OpNode RC:$r2, RD:$r1))], itin> {
  let Constraints = "$r2 = $r3";
  let isCommutable = isComm;	// e.g. add rb rc =  add rc rb
  let isReMaterializable = 1;
}


class CmpInstrR<bits<8> op, string instr_asm,
                  InstrItinClass itin, RegisterClass RC, RegisterClass RD,
                  RegisterClass RE, bit isComm = 0>:
  F2<op, (outs RE:$r3), (ins RC:$r1, RD:$r2),
     !strconcat(instr_asm, "\t$r1, $r2"), [], itin> {
  let isCommutable = isComm;	// e.g. add rb rc =  add rc rb
}
class CmpInstrI<bits<8> op, string instr_asm, string prefix,
                  Operand Od, PatLeaf imm_type, RegisterClass RD> :
  F3<op, (outs RD:$r2), (ins ACCs:$r1, Od:$offset),
    !strconcat(instr_asm, "\t", prefix, "$offset"), [], IIAlu> {
}
class CmpInstrI4<bits<8> op, string instr_asm, string prefix,
                  Operand Od, PatLeaf imm_type, RegisterClass RD> :
  F4<op, (outs RD:$r2), (ins ACCs:$r1, Od:$offset),
    !strconcat(instr_asm, "\t", prefix, "$offset"), [], IIAlu> {
}
multiclass CmpInstrM<bits<8> op, string instr_asm, bit isComm = 0> {
  let isCommutable = isComm in {
    let AddressUseMode = ImmediateAddressUse in {
      def i : CmpInstrI<op, instr_asm, "#", uimm12, immZExt12, SR>;
      def i4 : CmpInstrI4<op, instr_asm, "#", uimm20, immZExt20, SR>;
    }
    def il : CmpInstrI<op, instr_asm, "=", simm24, immSExt24, SR>;
  }
}


// Arithmetic and logical instructions with register + immediate operands.
// ADD, SUB, MUL, DIV, AND, OR, (COMP??? - probs not)
let Constraints = "$r2 = $r1", isReMaterializable = 1 in {
  class ArithLogicI<bits<8> op, string instr_asm, SDNode OpNode, string prefix,
                    Operand Od, PatLeaf imm_type, RegisterClass RC> :
    F3<op, (outs ACCs:$r2), (ins ACCs:$r1, Od:$offset),
      !strconcat(instr_asm, "\t", prefix, "$offset"),
      [(set ACCs:$r2, (OpNode ACCs:$r1, imm_type:$offset))], IIAlu> {
  }
  class ArithLogicI4<bits<8> op, string instr_asm, SDNode OpNode, string prefix,
                    Operand Od, PatLeaf imm_type, RegisterClass RC> :
    F4<op, (outs ACCs:$r2), (ins ACCs:$r1, Od:$offset),
      !strconcat(instr_asm, "\t", prefix, "$offset"),
      [(set ACCs:$r2, (OpNode ACCs:$r1, imm_type:$offset))], IIAlu> {
  }
}
multiclass ArithLogicM<bits<8> op, string instr_asm, SDNode OpNode, bit isComm = 0> {
  let isCommutable = isComm in {
    let AddressUseMode = ImmediateAddressUse in {
      def i : ArithLogicI<op, instr_asm, OpNode, "#", uimm12, immZExt12, CPURegs>;
      def i4 : ArithLogicI4<op, instr_asm, OpNode, "#", uimm20, immZExt20, CPURegs>;
    }
    def il : ArithLogicI<op, instr_asm, OpNode, "=", simm24, immSExt24, CPURegs>;
  }
}

// Shifts
// SHIFTL, SHIFTR
class shift_rotate_imm<bits<8> op, bits<4> isRotate, string instr_asm,
                       SDNode OpNode, PatFrag PF, Operand ImmOpnd,
                       RegisterClass RC>:
  F2<op, (outs GPROut:$r3), (ins RC:$r1, ImmOpnd:$r2),
     !strconcat(instr_asm, "\t$r1, $r2"),
     [(set GPROut:$r3, (OpNode RC:$r1, PF:$r2))], IIAlu> {
       let Constraints = "$r3 = $r1";
}

// 32-bit shift instructions.
class shift_rotate_imm32<bits<8> op, bits<4> isRotate, string instr_asm,
                         SDNode OpNode>:
  shift_rotate_imm<op, isRotate, instr_asm, OpNode, immZExt5, shamt, CPURegs>;

// Load Upper Imediate
class LoadImmediate<bits<8> op, string prefix, RegisterClass RC, Operand Imm,
AddressUseModesBits use>: F3<op, (outs RC:$r1), (ins Imm:$offset),
     !strconcat("LD", "$r1\t", prefix, "$offset"), [], IIAlu> {
  /* Immediate ranges:
   * F3: # -> 0..2^12 (4095), = -> anything
   * F4: # -> 0..2^20 (1048575), = -> anything
   */
  bits<4> r1;
  let AddressUseMode = use;
  let isReMaterializable = 1;
  let DecoderNamespace = "SIC-DecodeLoadImmediate";
  let hasCompleteDecoder = 0;
}
class LoadImmediate4<bits<8> op, string prefix, RegisterClass RC, Operand Imm,
AddressUseModesBits use>: F4<op, (outs RC:$r1), (ins Imm:$offset),
     !strconcat("LD", "$r1\t", prefix, "$offset"), [], IIAlu> {
  /* Immediate ranges:
   * F3: # -> 0..2^12 (4095), = -> anything
   * F4: # -> 0..2^20 (1048575), = -> anything
   */
  bits<4> r1;
  let AddressUseMode = use;
  let isReMaterializable = 1;
  let DecoderNamespace = "SIC-DecodeLoadImmediate";
  let hasCompleteDecoder = 0;
}

class FMem<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
          InstrItinClass itin>: F3<op, outs, ins, asmstr, pattern, itin> {
  let DecoderMethod = "DecodeMem";
}
class FMem4<bits<8> op, dag outs, dag ins, string asmstr, list<dag> pattern,
          InstrItinClass itin>: F4<op, outs, ins, asmstr, pattern, itin> {
  let DecoderMethod = "DecodeMem";
}

// Memory Load/Store
let canFoldAsLoad = 1 in
class LoadM<bits<8> op, string asmstr, PatFrag OpNode, RegisterClass RC,
            Operand MemOpnd, bit Pseudo>:
  FMem<op, (outs RC:$r1), (ins MemOpnd:$offset),
     !strconcat(asmstr, "\t$offset"),
     [(set RC:$r1, (OpNode addr:$offset))], IILoad> {
  let isPseudo = Pseudo;
}

class StoreM<bits<8> op, string asmstr, PatFrag OpNode, RegisterClass RC,
             Operand MemOpnd, bit Pseudo>:
  FMem<op, (outs), (ins RC:$r1, MemOpnd:$offset),
     !strconcat(asmstr, "\t$offset"),
     [(OpNode RC:$r1, addr:$offset)], IIStore> {
  let isPseudo = Pseudo;
}

// SICREAL - Load global
let canFoldAsLoad = 1 in
class LoadGlobal<bits<8> op, string asmstr, PatFrag OpNode, RegisterClass RC,
            Operand MemOpnd, bit Pseudo>:
  FMem4<op, (outs RC:$r1), (ins MemOpnd:$addr),
     !strconcat(asmstr, "\t$addr"),
     [(set RC:$r1, (OpNode (SICGlob tglobaladdr:$addr)))], IILoad> {
  let isPseudo = Pseudo;
}

class StoreGlobal<bits<8> op, string asmstr, PatFrag OpNode, RegisterClass RC,
             Operand MemOpnd, bit Pseudo>:
  FMem4<op, (outs), (ins RC:$r1, MemOpnd:$addr),
     !strconcat(asmstr, "\t$addr"),
     [(OpNode RC:$r1, (SICGlob tglobaladdr:$addr))], IIStore> {
  let isPseudo = Pseudo;
}

let canFoldAsLoad = 1 in
class LoadGlobalAddress<bits<8> op, string asmstr, PatFrag OpNode, RegisterClass RC,
            Operand MemOpnd, bit Pseudo>:
  FMem4<op, (outs RC:$r1), (ins MemOpnd:$addr),
     !strconcat(asmstr, "\t#$addr"),
     [(set RC:$r1, (SICGlob tglobaladdr:$addr))], IILoad> {
  let isPseudo = Pseudo;
  let AddressUseMode = ImmediateAddressUse;
}

multiclass LoadM32<bits<8> op, string asmstr, RegisterClass RC, PatFrag OpNode,
                   bit Pseudo = 0> {
  def #NAME# : LoadM<op, asmstr, OpNode, RC, mem, Pseudo>;
  def G : LoadGlobal<op, asmstr, OpNode, RC, mem_glob, Pseudo>;
  def ADR : LoadGlobalAddress<op, asmstr, OpNode, RC, mem_glob, Pseudo>;
  // GPROut
}

// 32-bit store.
multiclass StoreM32<bits<8> op, string asmstr, RegisterClass RC, PatFrag OpNode,
                    bit Pseudo = 0> {
  def #NAME# : StoreM<op, asmstr, OpNode, RC, mem, Pseudo>;
  def G :      StoreGlobal<op, asmstr, OpNode, RC, mem_glob, Pseudo>;
  // CPURegs
}


// TODO - Change this to pseudo and expand later?
class TempRegInstr<bits<6> Opcode2, string AsmInstr2, RegisterClass RC,
        RegisterClass RD, list<dag> pattern, InstrItinClass itin, string prefix = "">
        : Instruction {
  // STORE + LOAD
  let Namespace = "SIC";
  let Size = 8; // Using two form 4 entries
  let OutOperandList = (outs RD:$r2);
  let InOperandList = (ins RC:$r1);
  let AsmString = !strconcat("+ST$r1\tMEMREG\n", "\t+", AsmInstr2, "\t", prefix, "MEMREG");
  let Pattern = pattern;
  let Itinerary = itin;
  let canFoldAsLoad = 1;
  let mayLoad = 1;
  let mayStore = 1;
  let isCodeGenOnly = 1;

  bits<64> Inst;
  let Inst{63-56} = 0xEB;
  let Inst{57-52} = 0x31;
  let Inst{31-26} = Opcode2;
  let Inst{25-20} = 0x31;
}

class GetStatusWord<RegisterClass RD>: TempRegInstr<0x00, "LD$r2", SR, RD, [], IILoad>;

class ArithLogicTempReg<bits<6> Opcode2, string AsmInstr2, SDNode OpNode,
      RegisterClass RC, bit isComm = 0>: TempRegInstr<Opcode2, AsmInstr2, RC, ACCs,
            [(set ACCs:$r2, (OpNode ACCs:$rA, RC:$r1))], IIAlu> {
  let InOperandList = (ins ACCs:$rA, RC:$r1);
  let mayStore = 0; // TODO - FIX
  let isCommutable = isComm;
}

class LoadIndirectTempReg<bits<6> Opcode, string AsmInstr, PatFrag OpNode,
      RegisterClass RD> :
    TempRegInstr<Opcode, AsmInstr, CPURegs, RD,
    [(set RD:$r2, (OpNode CPURegs: $r1))], IILoad, "@"> {
  let Inst{24} = 1; // Indirect mode
  let mayStore = 0; // TODO - FIX
}

class StoreIndirectTempReg<bits<6> Opcode, string AsmInstr, PatFrag OpNode,
      RegisterClass RC> :
    TempRegInstr<Opcode, AsmInstr, RC, RegsNoA,
    [(OpNode RC:$r2, RegsNoA:$r1)], IIStore, "@"> {
  let OutOperandList = (outs);
  let InOperandList = (ins RegsNoA:$r1, RC:$r2);
  let Inst{24} = 1; // Indirect mode
}

// Conditional Branch, e.g. JEQ brtarget24
class CBranch24<bits<8> op, string instr_asm, RegisterClass RC,
                   list<Register> UseRegs>:
  F3<op, (outs), (ins RC:$ra, brtarget24:$addr),
             !strconcat(instr_asm, "\t$addr"),
             [], IIBranch> {
  let isBranch = 1;
  let isTerminator = 1;
  let hasDelaySlot = 1;
}

// Unconditional branch, such as JMP
let isBranch = 1, isTerminator = 1, isBarrier = 1, hasDelaySlot = 0 in {
  class UncondBranch3<bits<8> op, string instr_asm>:
    F3<op, (outs), (ins jmptarget:$offset),
              !strconcat(instr_asm, "\t$offset"), [(br bb:$offset)], IIBranch>;
  class UncondBranch4<bits<8> op, string instr_asm>:
    F4<op, (outs), (ins jmptarget:$address),
              !strconcat(instr_asm, "\t$address"), [(br bb:$address)], IIBranch>;
}
multiclass UncondBranch<bits<8> op, string instr_asm> {
  def #NAME# : UncondBranch3<op, instr_asm>;
  def f4 : UncondBranch4<op, instr_asm>;
}

let isBranch=1, isTerminator=1, isBarrier=1, offset =0, hasDelaySlot = 1,
    isIndirectBranch = 1, isReturn = 1, hasCtrlDep = 1, // isCodeGenOnly = 1
    hasExtraSrcRegAllocReq = 1 in
class RetBase<bits<8> op, string instr_asm>:
  F3<op, (outs), (ins RetRegs:$r1), instr_asm, [(brind RetRegs:$r1)], IIBranch> {
}


// Jump and Link (Call)
let isCall=1, hasDelaySlot=1 in {
  class JumpLink<bits<8> op, string instr_asm>:
    F3<op, (outs), (ins calltarget:$offset, variable_ops),
       !strconcat(instr_asm, "\t$offset"), [(SICJmpLink imm:$offset)],
       IIBranch> {
        let Defs = [L];
       }

  // TODO - Make it fake! Or pseudo!
  class JumpLinkReg<bits<8> op, string instr_asm,
                    RegisterClass RC>:
    F2<op, (outs), (ins RC:$r1, variable_ops),
       !strconcat(instr_asm, "\t$r1"), [(SICJmpLink RC:$r1)], IIBranch> {
    let Defs = [L];
    let r1 = 0;
  }
}

let isCall = 1, isTerminator = 1, isReturn = 1, isBarrier = 1, hasDelaySlot = 1,
    hasExtraSrcRegAllocReq = 1 in { // TODO - Defs?
  class TailCall<Instruction JumpInst> :
    PseudoSE<(outs), (ins calltarget:$target), [], IIBranch>,
    PseudoInstExpansion<(JumpInst jmptarget:$target)>;

  class TailCallReg<RegisterClass RO, Instruction JRInst,
                    RegisterClass ResRO = RO> :
    PseudoSE<(outs), (ins RO:$rs), [(SICTailCall RO:$rs)], IIBranch>,
    PseudoInstExpansion<(JRInst ResRO:$rs)>;
}

// TODO - Make this PSEUDO and fix in later stages!
// Currently a bit dangerous - uses X without telling LLVM
class EffectiveAddress<Operand Mem> :
    Instruction {
  // RMO + ADD
  let Namespace = "SIC";
  let Size = 5; // Using two form 4 entries
  let OutOperandList = (outs ACCs:$r2);
  let InOperandList = (ins Mem:$addr);
  let AsmString = !strconcat("RMO\tX, $r2\n", "\tADD\t#$addr");
  let Pattern = [(set ACCs:$r2, addr:$addr)];
  let Itinerary = NoItinerary;
  let isCodeGenOnly = 1;

  bits<40> Inst;
  let Inst{39-32} = 0xAC;
  let Inst{31-24} = 0x10;
  let Inst{23-16} = 0x19;
  let Inst{15-12} = 0x0;
  let Inst{11-0} = 0x4; // addr, actually
  }


//===----------------------------------------------------------------------===//
// Pseudo instructions
//===----------------------------------------------------------------------===//
// As stack alignment is always done with addiu, we need a 16-bit immediate
let Defs = [X], Uses = [X] in { // SIC SP -> X
def ADJCALLSTACKDOWN : SICPseudo<(outs), (ins uimm16:$amt),
                                  "!ADJCALLSTACKDOWN $amt",
                                  [(callseq_start timm:$amt)]>;
def ADJCALLSTACKUP   : SICPseudo<(outs), (ins uimm16:$amt1, uimm16:$amt2),
                                  "!ADJCALLSTACKUP $amt1",
                                  [(callseq_end timm:$amt1, timm:$amt2)]>;
}

// When handling PIC code the assembler needs .cpload and .cprestore
// directives. If the real instructions corresponding these directives
// are used, we have the same behavior, but get also a bunch of warnings
// from the assembler.
let hasSideEffects = 0 in
def CPRESTORE : SICPseudo<(outs), (ins i24imm:$loc, CPURegs:$gp),
                           ".cprestore\t$loc", []>;


//===----------------------------------------------------------------------===//
// SIC Instructions
//===----------------------------------------------------------------------===//

/// Load and Store Instructions
///  aligned
defm LD : LoadM32<0x00,  "LD$r1", GPROut, load>;
defm ST : StoreM32<0x0C, "ST$r1", CPURegs, store>;
// TODO - Maybe seperate instructions for different registers so we get correct opcodes?

defm LDCH : LoadM32<0x50, "LDCH", ACCs, extloadi8>;
defm STCH : StoreM32<0x54, "STCH", ACCs, truncstorei8>;

// Arithmetic Instructions (ALU Immediate)
defm ADD   : ArithLogicM<0x18, "ADD", add, 1>;
defm SUB   : ArithLogicM<0x1C, "SUB", sub, 0>;
defm MUL   : ArithLogicM<0x20, "MUL", mul, 1>;
defm DIV   : ArithLogicM<0x24, "DIV", sdiv, 0>;

defm AND    : ArithLogicM<0x40, "AND", and, 1>;
defm OR     : ArithLogicM<0x44, "OR", or, 1>;


def LDi  : LoadImmediate<0x00, "#", GPROut, uimm12, ImmediateAddressUse>;
def LDi4 : LoadImmediate4<0x00, "#", GPROut, uimm20, ImmediateAddressUse>;
def LDiL : LoadImmediate<0x00, "=", GPROut, simm24, SimpleAddressUse>;

def CMP     : CmpInstrR<0xA0, "COMPR", IIAlu, CPURegs, RegsNoA, SR, 0>;
defm CMP     : CmpInstrM<0x28, "COMP", 0>;

def ADD     : ArithLogicR<0x90, "ADDR", add, IIAlu, CPURegs, RegsNoA, 1>;
def SUB     : ArithLogicR<0x94, "SUBR", sub, IIAlu, CPURegs, RegsNoA, 0>;
def MUL     : ArithLogicR<0x98, "MULR", mul, IIImul, CPURegs, RegsNoA, 1>;
def DIV     : ArithLogicR<0x9C, "DIVR", sdiv, IIImul, CPURegs, RegsNoA, 0>;

def AND  : ArithLogicTempReg<0x10, "AND", and, RegsNoA, 1>;
def OR   : ArithLogicTempReg<0x14, "OR", or, RegsNoA, 1>;
def MVSW : GetStatusWord<GPROut>;
def LDIN : LoadIndirectTempReg<0x00, "LD$r2", load_a, GPROut>;
def STIN : StoreIndirectTempReg<0x0C, "ST$r2", store_a, CPURegs>;
def LDCHIN : LoadIndirectTempReg<0x12, "LDCH", extloadi8, ACCs>;
def STCHIN : StoreIndirectTempReg<0x13, "STCH", truncstorei8, ACCs>;


// Shift Instructions
def SHIFTR     : shift_rotate_imm32<0xA8, 0x00, "SHIFTR", sra>;
def SHIFTL     : shift_rotate_imm32<0xA4, 0x01, "SHIFTL", rotl>;

// Jump and Branch Instructions
def JEQ     : CBranch24<0x30, "JEQ", SR, [SW]>;
def JGT     : CBranch24<0x34, "JGT", SR, [SW]>;
def JLT     : CBranch24<0x38, "JLT", SR, [SW]>;

defm JMP     : UncondBranch<0x3C, "J">;

/// Jump & link and Return Instructions
def JSUB    : JumpLink<0x48, "JSUB">;

let isReturn=1, isTerminator=1, hasDelaySlot=1, isBarrier=1, hasCtrlDep=1 in
  def RetLR : SICPseudo<(outs), (ins), "", [(SICRet)]>;

def RET     : RetBase<0x4C, "RSUB">;

// def JALR    : JumpLinkReg<0x39, "jalr", GPROut>;


// No operation
  // SIC - We don't really have a nop? Just use unsupported 1 byte instr.
def NOP   : F1<0xF4, (outs), (ins), "HIO", [], IIAlu>;

def TAILCALL : TailCall<JMP>;

def LEA_SIC : EffectiveAddress<mem_sicea>;


let Constraints = "$r1 != $r2" in {
  def RMO: F2<0xAC, (outs GPROut:$r2),
    (ins GPROut:$r1), !strconcat("RMO", "\t$r1, $r2"),
    [/*(set GPROut:$r2, GPROut:$r1) RMO without pattern for now*/], IIAlu>;
}
let r2 = 0 in {
  def CLEAR: F2<0xB4, (outs GPROut:$r1), (ins), !strconcat("CLEAR", "\t$r1"),
     [(set GPROut:$r1, 0)], IIAlu>;
}

//===----------------------------------------------------------------------===//
//  Arbitrary patterns that map to one or more instructions
//===----------------------------------------------------------------------===//

// Small immediates
def : Pat<(i24 immZExt12:$in),
          (LDi imm:$in)>;
def : Pat<(i24 immZExt20:$in),
          (LDi4 imm:$in)>;
def : Pat<(i24 immSExt24:$in),
          (LDiL imm:$in)>;

// SICREAL - Shift Patterns
def : Pat<(shl CPURegs:$a, imm:$in),
          (ANDil (SHIFTL CPURegs:$a, imm:$in), (SHLMask imm:$in))>;

def : Pat<(srl CPURegs:$a, immIn12To16:$in),
          (ANDi (SHIFTR CPURegs:$a, immIn12To16:$in), (SRLMask immIn12To16:$in))>;
def : Pat<(srl CPURegs:$a, immIn4To11:$in),
          (ANDi4 (SHIFTR CPURegs:$a, immIn4To11:$in), (SRLMask immIn4To11:$in))>;
def : Pat<(srl CPURegs:$a, immIn1To4:$in),
          (ANDil (SHIFTR CPURegs:$a, immIn1To4:$in), (SRLMask immIn1To4:$in))>;

// SICREAL - XOR patterns
def XORi: Pat<(xor ACCs: $reg, immZExt12: $imm),
          (SUB (ORi ACCs: $reg, immZExt12: $imm), (ANDi ACCs: $reg, immZExt12: $imm))>;
def XORi4: Pat<(xor ACCs: $reg, immZExt20: $imm),
          (SUB (ORi4 ACCs: $reg, immZExt20: $imm), (ANDi4 ACCs: $reg, immZExt20: $imm))>;
def XORil: Pat<(xor ACCs: $reg, immSExt24: $imm),
          (SUB (ORil ACCs: $reg, immSExt24: $imm), (ANDil ACCs: $reg, immSExt24: $imm))>;

def XOR: Pat<(xor ACCs: $lhs, RegsNoA: $rhs),
          (SUB (OR ACCs: $lhs, RegsNoA: $rhs), (AND ACCs: $lhs, RegsNoA: $rhs))>;

// Div patterns
def : Pat<(udiv CPURegs:$lhs, CPURegs:$rhs),
          (DIV CPURegs:$lhs, CPURegs:$rhs)>;

multiclass ImmediatePatterns<SDNode originalNode, Instruction nodei,
  Instruction nodei4, Instruction nodeil> {
  def : Pat<(originalNode ACCs: $regs, immZExt12: $imm),
            (nodei ACCs: $regs, immZExt12: $imm)>;
  def : Pat<(originalNode ACCs: $regs, immZExt20: $imm),
            (nodei4 ACCs: $regs, immZExt20: $imm)>;
  def : Pat<(originalNode ACCs: $regs, immSExt24: $imm),
            (nodeil ACCs: $regs, immSExt24: $imm)>;
}

defm : ImmediatePatterns<udiv, DIVi, DIVi4, DIVil>;

// SIC - Check if these work or do we need a SICGlob DAG around it
def : Pat<(SICJmpLink (i24 tglobaladdr:$dst)),
          (JSUB tglobaladdr:$dst)>;
def : Pat<(SICJmpLink (i24 texternalsym:$dst)),
          (JSUB texternalsym:$dst)>;

def : Pat<(SICTailCall (iPTR tglobaladdr:$dst)),
              (TAILCALL tglobaladdr:$dst)>;
def : Pat<(SICTailCall (iPTR texternalsym:$dst)),
              (TAILCALL texternalsym:$dst)>;


// hi/lo relocs
def : Pat<(SICHi tglobaladdr:$in), (LDi4 tglobaladdr:$in)>;
def : Pat<(SICHi tblockaddress:$in), (LDi4 tblockaddress:$in)>;
def : Pat<(SICHi tjumptable:$in), (LDi4 tjumptable:$in)>;

def : Pat<(SICLo tglobaladdr:$in), (LDi tglobaladdr:$in)>;
def : Pat<(SICLo tblockaddress:$in), (LDi tblockaddress:$in)>;
def : Pat<(SICLo tjumptable:$in), (LDi tjumptable:$in)>;

def : Pat<(add CPURegs:$hi, (SICLo tglobaladdr:$lo)),
          (ORi CPURegs:$hi, tglobaladdr:$lo)>;

def : Pat<(add CPURegs:$gp, (SICGPRel tglobaladdr:$in)),
          (ORi CPURegs:$gp, tglobaladdr:$in)>;

class WrapperPat<SDNode node, Instruction ORiOp, RegisterClass RC>:
      Pat<(SICWrapper RC:$gp, node:$in),
              (ORiOp RC:$gp, node:$in)>;

def : WrapperPat<tglobaladdr, ORi, GPROut>;

def : WrapperPat<tjumptable, ORi, GPROut>;

def : Pat<(not CPURegs:$in),
// 1: in == 0; 0: in != 0
          (SUBi 1, CPURegs:$in)>;

def : Pat<(i24 (extloadi1  addr:$src)), (LDCH addr:$src)>;
def : Pat<(i24 (extloadi1  CPURegs:$src)), (LDCHIN CPURegs:$src)>;
def : Pat<(i24 (extloadi16_a addr:$src)), (LD addr:$src)>;
def : Pat<(i24 (extloadi16_a CPURegs:$src)), (LDIN CPURegs:$src)>;

def : Pat<(i24 (zextloadi1  addr:$src)), (ANDi (LDCH addr:$src), 1)>;
def : Pat<(i24 (zextloadi1  CPURegs:$src)), (ANDi (LDCHIN CPURegs:$src), 1)>;
def : Pat<(i24 (zextloadi8  addr:$src)), (ANDi (LDCH addr:$src), 0xFF)>;
def : Pat<(i24 (zextloadi8  CPURegs:$src)), (ANDi (LDCHIN CPURegs:$src), 0xFF)>;
def : Pat<(i24 (zextloadi16_a addr:$src)), (LD addr:$src)>;
def : Pat<(i24 (zextloadi16_a CPURegs:$src)), (LDIN CPURegs:$src)>;

def : Pat<(i24 (sextloadi8  addr:$src)), (SHIFTR (SHIFTL (LDCH addr:$src), 16), 16)>;
def : Pat<(i24 (sextloadi8  CPURegs:$src)), (SHIFTR (SHIFTL (LDCHIN CPURegs:$src), 16), 16)>;
def : Pat<(i24 (sextloadi16_a addr:$src)), (SHIFTR (SHIFTL (LD addr:$src), 8), 8)>;
def : Pat<(i24 (sextloadi16_a CPURegs:$src)), (SHIFTR (SHIFTL (LDCHIN CPURegs:$src), 8), 8)>;

// SIC - TODO - Correct truncstore requires no modification of register / wrong store
def : Pat<(truncstorei16_a CPURegs:$r1, addr:$offset), (ST (ANDi4 CPURegs:$r1, 0xFFFF), addr:$offset)>;


// brcond patterns
// brcond for cmp instruction
multiclass BrcondPatsCmp<RegisterClass RC, Instruction JEQOp, Instruction JNEOp,
Instruction JLTOp, Instruction JGTOp, Instruction JLEOp, Instruction JGEOp,
Instruction CMPOp> {
def : Pat<(brcond (i24 (seteq RC:$lhs, RC:$rhs)), bb:$dst),
          (JEQOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i24 (setueq RC:$lhs, RC:$rhs)), bb:$dst),
          (JEQOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i24 (setlt RC:$lhs, RC:$rhs)), bb:$dst),
          (JLTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i24 (setult RC:$lhs, RC:$rhs)), bb:$dst),
          (JLTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i24 (setgt RC:$lhs, RC:$rhs)), bb:$dst),
          (JGTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;
def : Pat<(brcond (i24 (setugt RC:$lhs, RC:$rhs)), bb:$dst),
          (JGTOp (CMPOp RC:$lhs, RC:$rhs), bb:$dst)>;

def : Pat<(brcond RC:$cond, bb:$dst),
          (JGTOp (CMPi RC:$cond, 0), bb:$dst)>;
}

defm : BrcondPatsCmp<CPURegs, JEQ, JEQ, JLT, JGT, JLT, JGT, CMP>;

// setcc patterns

// setcc for cmp instruction
multiclass SeteqPatsCmp<RegisterClass RC> {
// a == b
  def : Pat<(seteq RC:$lhs, immZExt12:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi RC:$lhs, immZExt12:$rhs), 0xC0), 7), 1)>;
  def : Pat<(seteq RC:$lhs, immZExt16:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi4 RC:$lhs, immZExt16:$rhs), 0xC0), 7), 1)>;
  def : Pat<(seteq RC:$lhs, RC:$rhs),
            (ANDi (SHIFTR (ADDi (CMP RC:$lhs, RC:$rhs), 0xC0), 7), 1)>;
// a != b
  def : Pat<(setne RC:$lhs, immZExt12:$rhs),
            (SHIFTR (ADDi (CMPi RC:$lhs, immZExt12:$rhs), 0x40), 7)>;
  def : Pat<(setne RC:$lhs, immZExt16:$rhs),
            (SHIFTR (ADDi (CMPi4 RC:$lhs, immZExt16:$rhs), 0x40), 7)>;
  def : Pat<(setne RC:$lhs, RC:$rhs),
            (SHIFTR (ADDi (CMP RC:$lhs, RC:$rhs), 0x40), 7)>;
}

// a < b
multiclass SetltPatsCmp<RegisterClass RC> {
  def : Pat<(setlt RC:$lhs, immZExt12:$rhs),
            (ANDi (SHIFTR (CMPi RC:$lhs, immZExt12:$rhs), 6), 1)>;
  def : Pat<(setlt RC:$lhs, immZExt16:$rhs),
            (ANDi (SHIFTR (CMPi4 RC:$lhs, immZExt16:$rhs), 6), 1)>;
  def : Pat<(setlt RC:$lhs, RC:$rhs),
            (ANDi (SHIFTR (CMP RC:$lhs, RC:$rhs), 6), 1)>;
  def : Pat<(setult RC:$lhs, immZExt12:$rhs),
            (ANDi (SHIFTR (CMPi RC:$lhs, immZExt12:$rhs), 6), 1)>;
  def : Pat<(setult RC:$lhs, immZExt16:$rhs),
            (ANDi (SHIFTR (CMPi4 RC:$lhs, immZExt16:$rhs), 6), 1)>;
  def : Pat<(setult RC:$lhs, RC:$rhs),
            (ANDi (SHIFTR (CMP RC:$lhs, RC:$rhs), 6), 1)>;
}

// a <= b
multiclass SetlePatsCmp<RegisterClass RC> {
  def : Pat<(setle RC:$lhs, immZExt12:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi RC:$lhs, immZExt12:$rhs), 0x80), 7), 1)>;
  def : Pat<(setle RC:$lhs, immZExt16:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi4 RC:$lhs, immZExt16:$rhs), 0x80), 7), 1)>;
  def : Pat<(setle RC:$lhs, RC:$rhs),
            (ANDi (SHIFTR (ADDi (CMP RC:$lhs, RC:$rhs), 0x80), 7), 1)>;

  def : Pat<(setule RC:$lhs, immZExt12:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi RC:$lhs, immZExt12:$rhs), 0x80), 7), 1)>;
  def : Pat<(setule RC:$lhs, immZExt16:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi4 RC:$lhs, immZExt16:$rhs), 0x80), 7), 1)>;
  def : Pat<(setule RC:$lhs, RC:$rhs),
            (ANDi (SHIFTR (ADDi (CMP RC:$lhs, RC:$rhs), 0x80), 7), 1)>;
}

// a > b
multiclass SetgtPatsCmp<RegisterClass RC> {
  def : Pat<(setgt RC:$lhs, immZExt12:$rhs),
            (SHIFTR (CMPi RC:$lhs, immZExt12:$rhs), 7)>;
  def : Pat<(setgt RC:$lhs, immZExt16:$rhs),
            (SHIFTR (CMPi4 RC:$lhs, immZExt16:$rhs), 7)>;
  def : Pat<(setgt RC:$lhs, RC:$rhs),
            (SHIFTR (CMP RC:$lhs, RC:$rhs), 7)>;

  def : Pat<(setugt RC:$lhs, immZExt12:$rhs),
            (SHIFTR (CMPi RC:$lhs, immZExt12:$rhs), 7)>;
  def : Pat<(setugt RC:$lhs, immZExt16:$rhs),
            (SHIFTR (CMPi4 RC:$lhs, immZExt16:$rhs), 7)>;
  def : Pat<(setugt RC:$lhs, RC:$rhs),
            (SHIFTR (CMP RC:$lhs, RC:$rhs), 7)>;
}

// a >= b
multiclass SetgePatsCmp<RegisterClass RC> {
  def : Pat<(setge RC:$lhs, immZExt12:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi RC:$lhs, immZExt12:$rhs), 0x40), 6), 1)>;
  def : Pat<(setge RC:$lhs, immZExt16:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi4 RC:$lhs, immZExt16:$rhs), 0x40), 6), 1)>;
  def : Pat<(setge RC:$lhs, RC:$rhs),
            (ANDi (SHIFTR (ADDi (CMP RC:$lhs, RC:$rhs), 0x40), 6), 1)>;

  def : Pat<(setuge RC:$lhs, immZExt12:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi RC:$lhs, immZExt12:$rhs), 0x40), 6), 1)>;
  def : Pat<(setuge RC:$lhs, immZExt16:$rhs),
            (ANDi (SHIFTR (ADDi (CMPi4 RC:$lhs, immZExt16:$rhs), 0x40), 6), 1)>;
  def : Pat<(setuge RC:$lhs, RC:$rhs),
            (ANDi (SHIFTR (ADDi (CMP RC:$lhs, RC:$rhs), 0x40), 6), 1)>;
}

defm : SeteqPatsCmp<CPURegs>;
defm : SetltPatsCmp<CPURegs>;
defm : SetlePatsCmp<CPURegs>;
defm : SetgtPatsCmp<CPURegs>;
defm : SetgePatsCmp<CPURegs>;
