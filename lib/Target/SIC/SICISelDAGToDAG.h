//===---- SICISelDAGToDAG.h - A Dag to Dag Inst Selector for SIC --------===//
//
//                     The LLVM Compiler Infrastructure
//
// This file is distributed under the University of Illinois Open Source
// License. See LICENSE.TXT for details.
//
//===----------------------------------------------------------------------===//
//
// This file defines an instruction selector for the SIC target.
//
//===----------------------------------------------------------------------===//

#ifndef LLVM_LIB_TARGET_SIC_SICISELDAGTODAG_H
#define LLVM_LIB_TARGET_SIC_SICISELDAGTODAG_H

#include "SIC.h"
#include "SICSubtarget.h"
#include "SICTargetMachine.h"
#include "llvm/CodeGen/SelectionDAGISel.h"
#include "llvm/IR/Type.h"
#include "llvm/Support/Debug.h"

//===----------------------------------------------------------------------===//
// Instruction Selector Implementation
//===----------------------------------------------------------------------===//

//===----------------------------------------------------------------------===//
// SICDAGToDAGISel - SIC specific code to select SIC machine
// instructions for SelectionDAG operations.
//===----------------------------------------------------------------------===//
namespace llvm {

class SICDAGToDAGISel : public SelectionDAGISel {
public:
  explicit SICDAGToDAGISel(SICTargetMachine &TM, CodeGenOpt::Level OL)
      : SelectionDAGISel(TM, OL), Subtarget(nullptr) {}

  // Pass Name
  const char *getPassName() const override {
    return "SIC DAG->DAG Pattern Instruction Selection";
  }

  bool runOnMachineFunction(MachineFunction &MF) override;

protected:
  SDNode *getGlobalBaseReg();

  /// Keep a pointer to the SICSubtarget around so that we can make the right
  /// decision when generating code for different targets.
  const SICSubtarget *Subtarget;

private:
  // Include the pieces autogenerated from the target description.
  #include "SICGenDAGISel.inc"

  /// getTargetMachine - Return a reference to the TargetMachine, casted
  /// to the target-specific type.
  const SICTargetMachine &getTargetMachine() {
    return static_cast<const SICTargetMachine &>(TM);
  }

  void Select(SDNode *N) override;

  bool trySelect(SDNode *Node);

  // Complex Pattern.
  bool SelectAddr(SDNode *Parent, SDValue N, SDValue &Base, SDValue &Offset);

  // getImm - Return a target constant with the specified value.
  inline SDValue getImm(const SDNode *Node, unsigned Imm) {
    return CurDAG->getTargetConstant(Imm, SDLoc(Node), Node->getValueType(0));
  }

  void processFunctionAfterISel(MachineFunction &MF);

  std::pair<SDNode *, SDNode *> selectMULT(SDNode *N, unsigned Opc,
                                           const SDLoc &DL, EVT Ty, bool HasLo,
                                           bool HasHi);

  void selectAddESubE(unsigned MOp, SDValue InFlag, SDValue CmpLHS,
                      const SDLoc &DL, SDNode *Node) const;
};

FunctionPass *createSICISelDag(SICTargetMachine &TM,
                                  CodeGenOpt::Level OptLevel);
}

#endif
