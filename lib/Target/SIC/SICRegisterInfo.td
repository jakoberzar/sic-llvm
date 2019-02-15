//===-- SICRegisterInfo.td - SIC Register defs -----------*- tablegen -*-===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
//  Declarations that describe the SIC register file
//===----------------------------------------------------------------------===//

// We have banks of 16 registers each.
class SICReg<bits<16> Enc, string n> : Register<n> {
  let HWEncoding = Enc;
  let Namespace = "SIC";
}

// SIC CPU Registers
class SICGPRReg<bits<16> Enc, string n> : SICReg<Enc, n>;

// PC Registers
class SICC0Reg<bits<16> Enc, string n> : SICReg<Enc, n>;

//===----------------------------------------------------------------------===//
// Registers
//===----------------------------------------------------------------------===//
// The register string, such as "9" or "gp" will show on "llvm-objdump -d"
// All registers definition
let Namespace = "SIC" in {
  // Real SIC GPRegs
  def A: SICGPRReg<0, "A">, DwarfRegNum<[0]>; // Accumulator
  def X: SICGPRReg<1, "X">, DwarfRegNum<[1]>; // Index register; for addressing
  def L: SICGPRReg<2, "L">, DwarfRegNum<[2]>; // Linkage register; used for jumping
  def B: SICGPRReg<3, "B">, DwarfRegNum<[3]>; // Base register, used for addressing
  def S: SICGPRReg<4, "S">, DwarfRegNum<[4]>; // Actually a general purpose register
  def T: SICGPRReg<5, "T">, DwarfRegNum<[5]>; // Actually a general pupropose register
  def F: SICGPRReg<6, "F">, DwarfRegNum<[6]>; // Floating point accumulator register - Actually 48 bits!

  def PC: SICC0Reg<8, "PC">, DwarfRegNum<[8]>; // PC
  def SW: SICGPRReg<9, "SW">, DwarfRegNum<[9]>; // SW
}

//===----------------------------------------------------------------------===//
// Register Classes
//===----------------------------------------------------------------------===//

def CPURegs : RegisterClass<"SIC", [i24], 32, (add
  // Accumulator
  A,
  // General purpose registers
  S, T,
  // Base Register
  B,
  // Index register
  X,
  // Linkage register - always need to store before calling a function!
  L,
  // Reserved
  SW)>;

def GPROut : RegisterClass<"SIC", [i24], 32, (add (sub CPURegs, SW))>;

def FPRegs : RegisterClass<"SIC", [f32], 32, (add F)>;

// Status Registers class
def SR     : RegisterClass<"SIC", [i24], 32, (add SW)>;

// PC Registers class
def C0Regs : RegisterClass<"SIC", [i24], 32, (add PC)>;

// Single register register classes
def ACCs : RegisterClass<"SIC", [i24], 32, (add A)>;
def RetRegs : RegisterClass<"SIC", [i24], 32, (add L)>;

// For two operand instructions, where both registers can't be A!
def RegsNoA : RegisterClass<"SIC", [i24], 32, (sub CPURegs, A)>;