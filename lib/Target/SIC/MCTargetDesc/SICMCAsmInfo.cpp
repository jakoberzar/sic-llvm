//===-- SICMCAsmInfo.cpp - SIC Asm Properties ---------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file contains the declarations of the SICMCAsmInfo properties.
//
//===----------------------------------------------------------------------===//

#include "SICMCAsmInfo.h"
#include "llvm/ADT/Triple.h"

using namespace llvm;

void SICMCAsmInfo::anchor() { }

SICMCAsmInfo::SICMCAsmInfo(const Triple &TheTriple) {
  if ((TheTriple.getArch() == Triple::sic))
    IsLittleEndian = false; // the default of IsLittleEndian is true

  AlignmentIsInBytes          = false;
  Data8bitsDirective          = "\tBYTE\t";
  Data16bitsDirective         = "\tWORD\t";//"\t.2byte\t";
  Data32bitsDirective         = "\tWORD\t";//"\t.4byte\t";
  Data64bitsDirective         = "\t.8byte\t";
  PrivateGlobalPrefix         = "_";
  PrivateLabelPrefix          = "_";
  CommentString               = ".";
  LabelSuffix                 = "";
  ZeroDirective               = "\tRESB\t";//"\t.space\t";
  GPRel32Directive            = "\t.gpword\t";
  GPRel64Directive            = "\t.gpdword\t";
  WeakRefDirective            = "\t.weak\t";
  UseAssignmentForEHBegin = true;

  SupportsDebugInformation = true;
  ExceptionsType = ExceptionHandling::DwarfCFI;
  DwarfRegNumForCFI = true;
}
