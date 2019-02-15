set(LLVM_TARGET_DEFINITIONS SICOther.td)

# Generate SICGenRegisterInfo.inc and SICGenInstrInfo.inc which included by
#  your hand code C++ files.
# SICGenRegisterInfo.inc came from SICRegisterInfo.td, SICGenInstrInfo.inc
#  came from SICInstrInfo.td.
tablegen(LLVM SICGenAsmMatcher.inc -gen-asm-matcher)
tablegen(LLVM SICGenRegisterInfo.inc -gen-register-info)
tablegen(LLVM SICGenInstrInfo.inc -gen-instr-info)
tablegen(LLVM SICGenDisassemblerTables.inc -gen-disassembler)
tablegen(LLVM SICGenCodeEmitter.inc -gen-emitter)
tablegen(LLVM SICGenMCCodeEmitter.inc -gen-emitter)

tablegen(LLVM SICGenAsmWriter.inc -gen-asm-writer)
tablegen(LLVM SICGenDAGISel.inc -gen-dag-isel)
tablegen(LLVM SICGenCallingConv.inc -gen-callingconv)
tablegen(LLVM SICGenSubtargetInfo.inc -gen-subtarget)
tablegen(LLVM SICGenMCPseudoLowering.inc -gen-pseudo-lowering)

# SICCommonTableGen must be defined
add_public_tablegen_target(SICCommonTableGen)

# SICCodeGen should match with LLVMBuild.txt SICCodeGen
add_llvm_target(SICCodeGen
  SICAsmPrinter.cpp
  SICMCInstLower.cpp
  SICDelUselessJMP.cpp
  SICFrameLowering.cpp
  SICInstrInfo.cpp
  SICISelLowering.cpp
  SICMachineFunction.cpp
  SICRegisterInfo.cpp
  SICSubtarget.cpp
  SICTargetObjectFile.cpp
  SICISelDAGToDAG.cpp
  SICTargetMachine.cpp
  )

# Should match with "subdirectories =  MCTargetDesc TargetInfo" in LLVMBuild.txt
add_subdirectory(InstPrinter)
add_subdirectory(TargetInfo)
add_subdirectory(MCTargetDesc)
add_subdirectory(AsmParser)
