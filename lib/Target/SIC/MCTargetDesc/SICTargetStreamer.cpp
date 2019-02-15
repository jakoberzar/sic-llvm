//===-- SICTargetStreamer.cpp - SIC Target Streamer Methods -------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file provides SIC specific target streamer methods.
//
//===----------------------------------------------------------------------===//

#include "InstPrinter/SICInstPrinter.h"
#include "SICMCTargetDesc.h"
#include "SICTargetObjectFile.h"
#include "SICTargetStreamer.h"
#include "llvm/MC/MCContext.h"
#include "llvm/MC/MCSectionELF.h"
#include "llvm/MC/MCSubtargetInfo.h"
#include "llvm/MC/MCSymbolELF.h"
#include "llvm/Support/CommandLine.h"
#include "llvm/Support/ELF.h"
#include "llvm/Support/ErrorHandling.h"
#include "llvm/Support/FormattedStream.h"

using namespace llvm;

SICTargetStreamer::SICTargetStreamer(MCStreamer &S)
    : MCTargetStreamer(S) {
}

SICTargetAsmStreamer::SICTargetAsmStreamer(MCStreamer &S,
                                             formatted_raw_ostream &OS)
    : SICTargetStreamer(S), OS(OS) {}
