# SIC/XE LLVM backend

This project contains the SIC/XE [(Simplified Instructional Computer)](https://en.wikipedia.org/wiki/Simplified_Instructional_Computer) backend for the LLVM compiler infrastructure.
The version of LLVM used is 3.9.

The modified clang compiler (with support for 24-bit integers that are used in SIC/XE) is available in the [sic-clang](https://github.com/jakoberzar/sic-clang) repository.

## Building

```bash
git clone --recurse-submodules https://github.com/jakoberzar/sic-llvm.git
cd sic-llvm
mkdir build
cd build
cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DLLVM_TARGETS_TO_BUILD="SIC" \
    -DCMAKE_C_COMPILER=clang \
    -DCMAKE_CXX_COMPILER=clang++ \
    -DLLVM_USE_LINKER=gold \
    -DLLVM_PARALLEL_LINK_JOBS=2 \
    ./../
make -j8
```

The built binaries are then available in the `build/bin` folder.

## Usage

- Compiling with `clang`:

  `./build/bin/clang -target sic-unknown-linux-gnu -S ./examples/SIC/fib-recursive.c -O3 -o fib-recursive.sic.asm`

- Compiling from C to LLVM IR with `clang`:

  `./build/bin/clang -target sic-unknown-linux-gnu -S -emit-llvm ./examples/SIC/fib-recursive.c -O3 -o fib-recursive.ll`

- Compiling from LLVM IR to SIC/XE assembly with `llc`:

  `./build/bin/llc ./fib-recursive.ll -O3 -o fib-recursive.sic.asm`

Relevant files are shown in the [EXAMPLE.md](./EXAMPLE.md) file

## Features

- Working compilation from C to SIC/XE assembly using the [sic-clang](https://github.com/jakoberzar/sic-clang) modified version of clang
- Use of 24-bit integers for the `int` data type
- It uses a set of conventions:
  - Register X is used as a stack pointer, as it can be used with indexed addressing
  - Arguments are passed via stack, as there aren't many registers available
  - Function results are returned in register S
  - A special symbol, MEMREG is used for loading and storing to arbitrary addresses in memory

## Current limitations

- No support for the standard library
- No support for the SIC/XE 48-bit floating point register
- No possible SIC object file program output
- Incomplete support for some LLVM IR instructions, which appear rarely or are a result of optimizations
- No support for inline SIC/XE assembly in C

## Location of modifications

The relevant modifications are spread accross the LLVM project, but can be mostly found in the `lib/Target/SIC` folder.

## More information

This work was done as a part of my bachelor's thesis, [LLVM backend for SIC/XE](http://eprints.fri.uni-lj.si/4360/), which includes setup instructions, a guide through the work done and some examples with results.
