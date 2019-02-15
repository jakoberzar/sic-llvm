//===-- SICELFObjectWriter.cpp - SIC ELF Writer -------------------------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
#include "MCTargetDesc/SICBaseInfo.h"
#include "MCTargetDesc/SICFixupKinds.h"
#include "MCTargetDesc/SICMCTargetDesc.h"
#include "llvm/MC/MCAssembler.h"
#include "llvm/MC/MCELFObjectWriter.h"
#include "llvm/MC/MCExpr.h"
#include "llvm/MC/MCSection.h"
#include "llvm/MC/MCValue.h"
#include "llvm/Support/ErrorHandling.h"
#include <list>

using namespace llvm;

namespace {
  class SICELFObjectWriter : public MCELFObjectTargetWriter {
  public:
    SICELFObjectWriter(uint8_t OSABI);

    ~SICELFObjectWriter() override;

    unsigned getRelocType(MCContext &Ctx, const MCValue &Target,
                        const MCFixup &Fixup, bool IsPCRel) const override;
    bool needsRelocateWithSymbol(const MCSymbol &Sym,
                                 unsigned Type) const override;
  };
}

SICELFObjectWriter::SICELFObjectWriter(uint8_t OSABI)
  : MCELFObjectTargetWriter(/*_is64Bit=false*/ false, OSABI, ELF::EM_SIC,
                            /*HasRelocationAddend*/ false) {}

SICELFObjectWriter::~SICELFObjectWriter() {}

unsigned SICELFObjectWriter::getRelocType(MCContext &Ctx,
                                           const MCValue &Target,
                                           const MCFixup &Fixup,
                                           bool IsPCRel) const {
  // determine the type of the relocation
  unsigned Type = (unsigned)ELF::R_SIC_NONE;
  unsigned Kind = (unsigned)Fixup.getKind();

  switch (Kind) {
  default:
    llvm_unreachable("invalid fixup kind!");
  case FK_Data_4:
    Type = ELF::R_SIC_32;
    break;
  case FK_GPRel_4:
    Type = ELF::R_SIC_GPREL32;
    break;
  case SIC::fixup_SIC_32:
    Type = ELF::R_SIC_32;
    break;
  case SIC::fixup_SIC_GPREL16:
    Type = ELF::R_SIC_GPREL16;
    break;
  case SIC::fixup_SIC_CALL16:
    Type = ELF::R_SIC_CALL16;
    break;
  case SIC::fixup_SIC_GOT:
    Type = ELF::R_SIC_GOT16;
    break;
  case SIC::fixup_SIC_HI16:
    Type = ELF::R_SIC_HI16;
    break;
  case SIC::fixup_SIC_LO16:
    Type = ELF::R_SIC_LO16;
    break;
  case SIC::fixup_SIC_PC16:
    Type = ELF::R_SIC_PC16;
    break;
  case SIC::fixup_SIC_PC24:
    Type = ELF::R_SIC_PC24;
    break;
  case SIC::fixup_SIC_GOT_HI16:
    Type = ELF::R_SIC_GOT_HI16;
    break;
  case SIC::fixup_SIC_GOT_LO16:
    Type = ELF::R_SIC_GOT_LO16;
    break;
  }

  return Type;
}

bool
SICELFObjectWriter::needsRelocateWithSymbol(const MCSymbol &Sym,
                                             unsigned Type) const {
  // FIXME: This is extremelly conservative. This really needs to use a
  // whitelist with a clear explanation for why each realocation needs to
  // point to the symbol, not to the section.
  switch (Type) {
  default:
    return true;

  case ELF::R_SIC_GOT16:
  // For SIC pic mode, I think it's OK to return true but I didn't confirm.
  //  llvm_unreachable("Should have been handled already");
    return true;

  // These relocations might be paired with another relocation. The pairing is
  // done by the static linker by matching the symbol. Since we only see one
  // relocation at a time, we have to force them to relocate with a symbol to
  // avoid ending up with a pair where one points to a section and another
  // points to a symbol.
  case ELF::R_SIC_HI16:
  case ELF::R_SIC_LO16:
  // R_SIC_32 should be a relocation record, I don't know why Mips set it to
  // false.
  case ELF::R_SIC_32:
    return true;

  case ELF::R_SIC_GPREL16:
    return false;
  }
}

MCObjectWriter *llvm::createSICELFObjectWriter(raw_pwrite_stream &OS,
                                                uint8_t OSABI,
                                                bool IsLittleEndian) {
  MCELFObjectTargetWriter *MOTW = new SICELFObjectWriter(OSABI);
  return createELFObjectWriter(MOTW, OS, IsLittleEndian);
}
