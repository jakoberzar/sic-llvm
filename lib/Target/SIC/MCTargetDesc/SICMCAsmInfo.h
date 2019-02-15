//===-- SICMCAsmInfo.h - SIC Asm Info ------------------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declaration of the SICMCAsmInfo class.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICMCASMINFO_H
#define LLVM_LIB_TARGET_SIC_MCTARGETDESC_SICMCASMINFO_H

#include "llvm/MC/MCAsmInfoELF.h"

namespace llvm {
  class Triple;

  class SICMCAsmInfo : public MCAsmInfoELF {
    void anchor() override;
  public:
    explicit SICMCAsmInfo(const Triple &TheTriple);
  };

} // namespace llvm

#endif
