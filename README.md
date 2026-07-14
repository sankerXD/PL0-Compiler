<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
  <a href="README.zh-CN.md"><img src="https://img.shields.io/badge/lang-简体中文-red.svg" alt="简体中文"></a>
</p>

# PL0-Compiler

A course-project compiler front-end for **PL/0** (a small Pascal-like teaching language), built with **Flex** (lexer generator) and **Bison/Yacc** (parser generator). It performs lexical analysis, syntax analysis, and generates P-code-style intermediate code.

## Why rewrite it this way

Textbook PL/0 compilers are usually hand-written, procedural C code — correct, but hard to read since lexing and parsing logic are tangled together. This version instead uses the standard Flex/Bison toolchain: the grammar is expressed declaratively as BNF-style productions, and semantic actions (symbol-table bookkeeping, code generation) are attached directly to each production.

## Structure

| File | Purpose |
|---|---|
| `mylex.l` | Flex source: token definitions for PL/0 keywords, operators, numbers, identifiers |
| `myyacc.y` | Bison source: PL/0 grammar plus the semantic actions that drive symbol-table and code generation |
| `MakeInterCode.h` | Declarations: instruction set, symbol-table structure, code-stack structure, and all helper function prototypes |
| `MakeInterCode.c` | Implementation of the symbol table and intermediate-code generation (including nested-block handling and jump backpatching) |
| `calc/` | A minimal Flex/Bison calculator example kept as a reference (not part of the PL/0 compiler) |

Generated parser/lexer C files, `.output` files, and compiled binaries are **not** checked in — see `.gitignore`. Regenerate them with the build steps below.

## How it works

1. **Lexer (`mylex.l`)** — regex rules recognize each PL/0 keyword/operator/number/identifier, print the token, and `return` it to the parser, stashing the token text/value in `yylval`.

2. **Parser (`myyacc.y`)** — the grammar is split into two halves: declarations (const/var/procedure, which register names into the symbol table) and statements (assignment/if/while/call/read/write, which look up names in the symbol table and emit intermediate code).

3. **Symbol table & code generation (`MakeInterCode.h`/`.c`)** — a custom instruction set (`lit/lod/sto/cal/opr/ict/jmp/jpc/ret`) modeled on the classic PL/0 P-code, plus:
   - **Nested procedure scopes**, tracked via a `level` counter plus per-level saved state (`endIndex[]` / `blockLength[]`).
   - **Jump backpatching** — forward jumps (`if`/`while`/block entry) are emitted with a placeholder target and patched once the real address is known (`backPath()`).

## Build

```sh
flex -o mylex.c mylex.l
bison -d -o myyacc.c myyacc.y
gcc mylex.c myyacc.c MakeInterCode.c -o pl0c
```

Run the resulting binary, choose "1" to load a `.pas`/`.txt` PL/0 source file, "2" to run lexical + syntax analysis, "3" to print the generated intermediate code.

## PL/0 grammar (simplified BNF)

```
Program    -> Block .
Block      -> [ConstDecl] [VarDecl] [ProcDecl] Stmt
ConstDecl  -> const ConstDef {, ConstDef} ;
VarDecl    -> var ident {, ident} ;
ProcDecl   -> procedure ident ; Block ; {procedure ident ; Block ;}
Stmt       -> ident := Exp | call ident | begin Stmt {; Stmt} end
            | if Cond then Stmt | while Cond do Stmt | ε
Cond       -> odd Exp | Exp RelOp Exp
Exp        -> [+|-] Term {+ Term | - Term}
Term       -> Factor {* Factor | / Factor}
Factor     -> ident | number | ( Exp )
```
