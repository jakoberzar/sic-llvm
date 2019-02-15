//===-- SICFixupKinds.h - SIC Specific Fixup Entries ----------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICFIXUPKINDS_H
#define LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICFIXUPKINDS_H

#include "llvm/MC/MCFixup.h"

namespace llvm {
namespace SIC {
  // Although most of the current fixup types reflect a unique relocation
  // one can have multiple fixup types for a given relocation and thus need
  // to be uniquely named.
  //
  // This table *must* be in the save order of
  // MCFixupKindInfo Infos[SIC::NumTargetFixupKinds]
  // in SICAsmBackend.cpp.
  enum Fixups {
    // Pure upper 32 bit fixup resulting in - R_SIC_32.
    fixup_SIC_32 = FirstTargetFixupKind,

    // Pure upper 16 bit fixup resulting in - R_SIC_HI16.
    fixup_SIC_HI16,

    // Pure lower 16 bit fixup resulting in - R_SIC_LO16.
    fixup_SIC_LO16,

    // 16 bit fixup for GP offest resulting in - R_SIC_GPREL16.
    fixup_SIC_GPREL16,

    // Symbol fixup resulting in - R_SIC_GOT16.
    fixup_SIC_GOT,

    // PC relative branch fixup resulting in - R_SIC_PC16.
    // sic PC16, e.g. beq
    fixup_SIC_PC16,

    // PC relative branch fixup resulting in - R_SIC_PC24.
    // sic PC24, e.g. jeq, jmp
    fixup_SIC_PC24,

    // resulting in - R_SIC_CALL16.
    fixup_SIC_CALL16,

    // resulting in - R_SIC_GOT_HI16
    fixup_SIC_GOT_HI16,

    // resulting in - R_SIC_GOT_LO16
    fixup_SIC_GOT_LO16,

    // Marker
    LastTargetFixupKind,
    NumTargetFixupKinds = LastTargetFixupKind - FirstTargetFixupKind
  };
} // namespace SIC
} // namespace llvm

#endif // LLVM_SIC_SICFIXUPKINDS_H
