//===-- SICTargetStreamer.h - SIC Target Streamer ------------*- C++ -*--===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SIC_SICTARGETSTREAMER_H
#define LLVM_LIB_TARGET_SIC_SICTARGETSTREAMER_H

#include "llvm/MC/MCELFStreamer.h"
#include "llvm/MC/MCRegisterInfo.h"
#include "llvm/MC/MCStreamer.h"

namespace llvm {

class SICTargetStreamer : public MCTargetStreamer {
public:
  SICTargetStreamer(MCStreamer &S);
};

// This part is for ascii assembly output
class SICTargetAsmStreamer : public SICTargetStreamer {
  formatted_raw_ostream &OS;

public:
  SICTargetAsmStreamer(MCStreamer &S, formatted_raw_ostream &OS);
};

}

#endif
