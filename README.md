# SIC/XE LLVM backend

This project contains the SIC/XE [(Simplified Instructional Computer)](https://en.wikipedia.org/wiki/Simplified_Instructional_Computer) backend for the LLVM compiler infrastructure.

The modified clang compiler (with support for 24-bit integers that are used in SIC/XE) is available in the [sic-clang](https://github.com/jakoberzar/sic-clang) repository.

## Features

- Working compilation from C to SIC/XE assembly using the [sic-clang](https://github.com/jakoberzar/sic-clang) modified version of clang
- Use of 24-bit integers for the `int` data type

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
