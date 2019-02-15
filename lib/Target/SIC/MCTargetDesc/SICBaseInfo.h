//===-- SICBaseInfo.h - Top level definitions for SIC MC ------*- C++ -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains small standalone helper functions and enum definitions for
// the SIC target useful for the compiler back-end and the MC libraries.
//
//===----------------------------------------------------------------------===//
#ifndef LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICBASEINFO_H
#define LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICBASEINFO_H

#include "SICFixupKinds.h"
#include "SICMCTargetDesc.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/Support/DataTypes.h"
#include "llvm/Support/ErrorHandling.h"

namespace llvm {

/// SICII - This namespace holds all of the target specific flags that
/// instruction info tracks.
namespace SICII {
  /// Target Operand Flag enum.
  enum TOF {
    //===------------------------------------------------------------------===//
    // SIC Specific MachineOperand flags.

    MO_NO_FLAG,

    /// MO_GOT - Represents the offset into the global offset table at which
    /// the address the relocation entry symbol resides during execution.
    MO_GOT,

    /// MO_GOT_CALL - Represents the offset into the global offset table at
    /// which the address of a call site relocation entry symbol resides
    /// during execution. This is different from the above since this flag
    /// can only be present in call instructions.
    MO_GOT_CALL,

    /// MO_GPREL - Represents the offset from the current gp value to be used
    /// for the relocatable object file being produced.
    MO_GPREL,

    /// MO_ABS_HI/LO - Represents the hi or low part of an absolute symbol
    /// address.
    MO_ABS_HI,
    MO_ABS_LO,

    /// MO_GOT_HI16/LO16 - Relocations used for large GOTs.
    MO_GOT_HI16,
    MO_GOT_LO16
  }; // enum TOF {

  enum {
    //===------------------------------------------------------------------===//
    // Instruction encodings.  These are the standard/most common forms for
    // SIC instructions.
    //

    // Pseudo - This represents an instruction that is a pseudo instruction
    // or one that has not been implemented yet.  It is illegal to code generate
    // it, but tolerated for intermediate implementation stages.
    Pseudo = 0,

    /// Frm1 - This form is for instructions of the format 1.
    Frm1 = 1,
    /// Frm2 - This form is for instructions of the format 2.
    Frm2 = 2,
    /// Frm3 - This form is for instructions of the format 3.
    Frm3 = 3,
    /// Frm4 - This form is for instructions of the format 4.
    Frm4 = 4,
    /// FrmOther - This form is for instructions that have no specific format.
    FrmOther = 5,

    FormMask = 15
  };
}

}

#endif
