//===-- SICMCTargetDesc.h - SIC Target Descriptions -----------*- C++ -*-===//
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

#ifndef LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICMCTARGETDESC_H
#define LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICMCTARGETDESC_H

#include "llvm/Support/DataTypes.h"

namespace llvm {
class MCAsmBackend;
class MCCodeEmitter;
class MCContext;
class MCInstrInfo;
class MCObjectWriter;
class MCRegisterInfo;
class MCSubtargetInfo;
class StringRef;
class Target;
class Triple;
class raw_ostream;
class raw_pwrite_stream;

extern Target TheSICTarget;

MCCodeEmitter *createSICMCCodeEmitterEB(const MCInstrInfo &MCII,
                                         const MCRegisterInfo &MRI,
                                         MCContext &Ctx);
MCCodeEmitter *createSICMCCodeEmitterEL(const MCInstrInfo &MCII,
                                         const MCRegisterInfo &MRI,
                                         MCContext &Ctx);

MCAsmBackend *createSICAsmBackendEB32(const Target &T,
                                       const MCRegisterInfo &MRI,
                                       const Triple &TT, StringRef CPU);
MCAsmBackend *createSICAsmBackendEL32(const Target &T,
                                       const MCRegisterInfo &MRI,
                                       const Triple &TT, StringRef CPU);

MCObjectWriter *createSICELFObjectWriter(raw_pwrite_stream &OS,
                                          uint8_t OSABI,
                                          bool IsLittleEndian);
} // End llvm namespace

// Defines symbolic names for SIC registers.  This defines a mapping from
// register name to register number.
#define GET_REGINFO_ENUM
#include "SICGenRegisterInfo.inc"

// Defines symbolic names for the SIC instructions.
#define GET_INSTRINFO_ENUM
#include "SICGenInstrInfo.inc"

#define GET_SUBTARGETINFO_ENUM
#include "SICGenSubtargetInfo.inc"

#endif
