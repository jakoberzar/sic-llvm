//===-- SICInstrInfo.cpp - SIC Instruction Information ------------------===//
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

#include "SICInstrInfo.h"
#include "InstPrinter/SICInstPrinter.h"
#include "SICTargetMachine.h"
#include "SICMachineFunction.h"
#include "llvm/ADT/STLExtras.h"
#include "llvm/CodeGen/MachineInstrBuilder.h"
#include "llvm/CodeGen/MachineRegisterInfo.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/TargetRegistry.h"

using namespace llvm;

#define GET_INSTRINFO_CTOR_DTOR
#include "SICGenInstrInfo.inc"

// Pin the vtable to this file.
void SICInstrInfo::anchor() {}

SICInstrInfo::SICInstrInfo(const SICSubtarget &STI)
    :
      SICGenInstrInfo(SIC::ADJCALLSTACKDOWN, SIC::ADJCALLSTACKUP),
      Subtarget(STI), RI(STI) {}

const SICInstrInfo *SICInstrInfo::create(SICSubtarget &STI) {
  return new SICInstrInfo(STI);
}

const SICRegisterInfo &SICInstrInfo::getRegisterInfo() const {
  return RI;
}

MachineMemOperand *
SICInstrInfo::GetMemOperand(MachineBasicBlock &MBB, int FI,
                             MachineMemOperand::Flags Flags) const {

  MachineFunction &MF = *MBB.getParent();
  MachineFrameInfo &MFI = *MF.getFrameInfo();
  unsigned Align = MFI.getObjectAlignment(FI);

  return MF.getMachineMemOperand(MachinePointerInfo::getFixedStack(MF, FI),
                                 Flags, MFI.getObjectSize(FI), Align);
}

/// Return the number of bytes of code the specified instruction may be.
unsigned SICInstrInfo::GetInstSizeInBytes(const MachineInstr &MI) const {
  switch (MI.getOpcode()) {
  default:
    return MI.getDesc().getSize();
  }
}


void SICInstrInfo::copyPhysReg(MachineBasicBlock &MBB,
                                  MachineBasicBlock::iterator I,
                                  const DebugLoc &DL, unsigned DestReg,
                                  unsigned SrcReg, bool KillSrc) const {
  unsigned Opc = 0;
  if (SIC::GPROutRegClass.contains(DestReg) && SIC::GPROutRegClass.contains(SrcReg)) {
    Opc = SIC::RMO;
  } else if (SIC::GPROutRegClass.contains(DestReg) && SIC::SW == SrcReg) {
    Opc = SIC::MVSW;
  }

  assert(Opc && "Cannot copy registers");

  MachineInstrBuilder MIB = BuildMI(MBB, I, DL, get(Opc));

  if (DestReg)
    MIB.addReg(DestReg, RegState::Define);

  if (SrcReg)
    MIB.addReg(SrcReg, getKillRegState(KillSrc));
}

void SICInstrInfo::
storeRegToStack(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                unsigned SrcReg, bool isKill, int FI,
                const TargetRegisterClass *RC, const TargetRegisterInfo *TRI,
                int64_t Offset) const {
  DebugLoc DL;
  MachineMemOperand *MMO = GetMemOperand(MBB, FI, MachineMemOperand::MOStore);

  unsigned Opc = 0;

  Opc = SIC::ST;
  assert(Opc && "Register class not handled!");
  BuildMI(MBB, I, DL, get(Opc)).addReg(SrcReg, getKillRegState(isKill))
    .addFrameIndex(FI).addImm(Offset).addMemOperand(MMO);
}

void SICInstrInfo::
loadRegFromStack(MachineBasicBlock &MBB, MachineBasicBlock::iterator I,
                 unsigned DestReg, int FI, const TargetRegisterClass *RC,
                 const TargetRegisterInfo *TRI, int64_t Offset) const {
  DebugLoc DL;
  if (I != MBB.end()) DL = I->getDebugLoc();
  MachineMemOperand *MMO = GetMemOperand(MBB, FI, MachineMemOperand::MOLoad);
  unsigned Opc = 0;

  Opc = SIC::LD;
  assert(Opc && "Register class not handled!");
  BuildMI(MBB, I, DL, get(Opc), DestReg).addFrameIndex(FI).addImm(Offset)
    .addMemOperand(MMO);
}

/// Expand Pseudo instructions into real backend instructions
bool SICInstrInfo::expandPostRAPseudo(MachineInstr &MI) const {
  MachineBasicBlock &MBB = *MI.getParent();

  switch (MI.getDesc().getOpcode()) {
  default:
    return false;
  case SIC::RetLR:
    expandRetLR(MBB, MI);
    break;
  }

  MBB.erase(MI);
  return true;
}

/// Adjust SP by Amount bytes.
void SICInstrInfo::adjustStackPtr(unsigned SP, int64_t Amount,
                                     MachineBasicBlock &MBB,
                                     MachineBasicBlock::iterator I) const {
  DebugLoc DL = I != MBB.end() ? I->getDebugLoc() : DebugLoc();
  unsigned ADDR = SIC::ADD;
  unsigned SUBR = SIC::SUB;
  unsigned LDi = SIC::LDi;
  unsigned LDi4 = SIC::LDi4;
  unsigned LDiL = SIC::LDiL;
  unsigned T = SIC::T;

  if (isUInt<20>(Amount)) {
    // lda #amount
    if (isUInt<12>(Amount)) {
      BuildMI(MBB, I, DL, get(LDi), T).addImm(Amount);
    } else {
      BuildMI(MBB, I, DL, get(LDi4), T).addImm(Amount);
    }
    // addr A, SP
    BuildMI(MBB, I, DL, get(ADDR), SP).addReg(SP).addReg(T);
  } else if (isUInt<20>(-Amount)) {
    // lda #amount
    if (isUInt<12>(-Amount)) {
      BuildMI(MBB, I, DL, get(LDi), T).addImm(-Amount);
    } else {
      BuildMI(MBB, I, DL, get(LDi4), T).addImm(-Amount);
    }
    // subr A, SP
    BuildMI(MBB, I, DL, get(SUBR), SP).addReg(SP).addReg(T);
  }
  else { // Expand immediate that doesn't fit in 12-bit.
    // lda =amount
    BuildMI(MBB, I, DL, get(LDiL), T).addImm(Amount);
    // addr A, SP
    BuildMI(MBB, I, DL, get(ADDR), SP).addReg(SP).addReg(T);
  }
}

void SICInstrInfo::expandRetLR(MachineBasicBlock &MBB,
                                MachineBasicBlock::iterator I) const {
  BuildMI(MBB, I, I->getDebugLoc(), get(SIC::RET)).addReg(SIC::L); //SICREAL LR -> L
}
