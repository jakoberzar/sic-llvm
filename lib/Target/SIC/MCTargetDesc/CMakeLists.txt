# MCTargetDesc/CMakeLists.txt
add_llvm_library(LLVMSICDesc
  SICABIInfo.cpp
  SICMCAsmInfo.cpp
  SICAsmBackend.cpp
  SICMCCodeEmitter.cpp
  SICMCExpr.cpp
  SICELFObjectWriter.cpp
  SICTargetStreamer.cpp
  SICMCTargetDesc.cpp
  )
