# Example usage

## Compilation
### Compiling from C to SIC with clang

We use the following command to compile the program [./examples/SIC/fib-recursive.c](./examples/SIC/fib-recursive.c) with -O3 optimizations to a SIC/XE assembly file named `fib-recursive.sic.asm`:

`./build/bin/clang -target sic-unknown-linux-gnu -S ./examples/SIC/fib-recursive.c -O3 -o fib-recursive.sic.asm`

### Compiling from C to SIC via LLVM IR (using clang and llc)

#### C -> LLVM IR with clang

We use the following command to compile the program [./examples/SIC/fib-recursive.c](./examples/SIC/fib-recursive.c) with -O3 optimizations to an LLVM IR file named `fib-recursive.ll`:

`./build/bin/clang -target sic-unknown-linux-gnu -S -emit-llvm ./examples/SIC/fib-recursive.c -O3 -o fib-recursive.ll`

#### LLVM IR -> SIC with clang

We use the following command to compile the file `fib-recursive.ll`, created in previous step, to a SIC/XE assembly file called `fib-recursive.sic.asm`:

`./build/bin/llc ./fib-recursive.ll -O3 -o fib-recursive.sic.asm`

## Relevant files:

**fib-recursive.c**

```c
int fib(int n) {
  if (n <= 2)
    return 1;
  else
    return fib(n - 1) + fib(n - 2);
}

int main() { return fib(10); }
```

**fib-recursive.sic.asm**

```sic
	.text
	+LDX	#0xFFFFC
	JSUB	main
halt	J	halt
	.file	"./examples/SIC/fib-recursive.c"
	.globl	fib
	.p2align	2
	.type	fib,@function
fib
	LDT	#24
	SUBR	T, X
	STL	20, X
	LDT	#1
	LDA	24, X
	LDS	#3
	COMPR	A, S
	JLT	_BB0_3
	LDT	#1
_BB0_2
	STA	16, X
	STT	12, X
	LDA	16, X
	ADD	=-1
	+STX	MEMREG
	+STA	@MEMREG
	JSUB	fib
	LDA	16, X
	LDT	12, X
	ADDR	S, T
	ADD	=-2
	LDS	#2
	COMPR	A, S
	JGT	_BB0_2
_BB0_3
	RMO	T, S
	LDL	20, X
	LDT	#24
	ADDR	T, X
	RSUB
_func_end0
	.size	fib, _func_end0-fib
	EQU	*
	LTORG

	.globl	main
	.p2align	2
	.type	main,@function
main
	LDT	#16
	SUBR	T, X
	STL	12, X
	LDA	#10
	+STX	MEMREG
	+STA	@MEMREG
	JSUB	fib
	LDL	12, X
	LDT	#16
	ADDR	T, X
	RSUB
_func_end1
	.size	main, _func_end1-main
	EQU	*
	LTORG


	.ident	"clang version 3.9.0 (tags/RELEASE_390/final)"
	.section	".note.GNU-stack","",@progbits
MEMREG	RESW	1
```

**fib-recursive.ll**

```llvm
; ModuleID = './examples/SIC/fib-recursive.c'
source_filename = "./examples/SIC/fib-recursive.c"
target datalayout = "E-p:24:32-i8:8:32-i16:16:32-i24:32-n24-S32"
target triple = "sic-unknown-linux-gnu"

; Function Attrs: nounwind readnone
define i24 @fib(i24) local_unnamed_addr #0 {
  %2 = icmp slt i24 %0, 3
  br i1 %2, label %13, label %3

; <label>:3:                                      ; preds = %1
  br label %4

; <label>:4:                                      ; preds = %3, %4
  %5 = phi i24 [ %9, %4 ], [ %0, %3 ]
  %6 = phi i24 [ %10, %4 ], [ 1, %3 ]
  %7 = add nsw i24 %5, -1
  %8 = tail call i24 @fib(i24 %7)
  %9 = add nsw i24 %5, -2
  %10 = add nsw i24 %8, %6
  %11 = icmp slt i24 %9, 3
  br i1 %11, label %12, label %4

; <label>:12:                                     ; preds = %4
  br label %13

; <label>:13:                                     ; preds = %12, %1
  %14 = phi i24 [ 1, %1 ], [ %10, %12 ]
  ret i24 %14
}

; Function Attrs: nounwind readnone
define i24 @main() local_unnamed_addr #0 {
  %1 = tail call i24 @fib(i24 10)
  ret i24 %1
}

attributes #0 = { nounwind readnone "disable-tail-calls"="false" "less-precise-fpmad"="false" "no-frame-pointer-elim"="true" "no-frame-pointer-elim-non-leaf" "no-infs-fp-math"="false" "no-jump-tables"="false" "no-nans-fp-math"="false" "no-signed-zeros-fp-math"="false" "stack-protector-buffer-size"="8" "unsafe-fp-math"="false" "use-soft-float"="false" }

!llvm.ident = !{!0}

!0 = !{!"clang version 3.9.0 (tags/RELEASE_390/final)"}
```
