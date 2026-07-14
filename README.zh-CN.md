<p align="center">
  <a href="README.md"><img src="https://img.shields.io/badge/lang-English-blue.svg" alt="English"></a>
  <a href="README.zh-CN.md"><img src="https://img.shields.io/badge/lang-简体中文-red.svg" alt="简体中文"></a>
</p>

# PL0-Compiler

这是一个编译原理课程设计项目：用 **Flex**（词法分析器生成器）与 **Bison/Yacc**（语法分析器生成器）为教学语言 **PL/0**（Pascal 的简化子集）实现词法分析、语法分析，并生成类 P-code 中间代码。

## 设计初衷

教材上的 PL/0 编译器通常是手写的面向过程 C 代码，词法识别和语句处理混在一起，代码阅读门槛较高。本项目改用标准的 Flex/Bison 工具链重新实现：语法规则以 BNF 产生式的形式声明式书写，符号表登记与中间代码生成等语义动作直接挂在对应产生式上。

## 目录结构

| 文件 | 作用 |
|---|---|
| `mylex.l` | 词法规则：关键字、运算符、数字、标识符的定义与识别 |
| `myyacc.y` | 语法规则：PL/0 产生式，以及驱动符号表登记与中间代码生成的语义动作 |
| `MakeInterCode.h` | 声明：指令集、符号表结构、中间代码栈结构及所有辅助函数原型 |
| `MakeInterCode.c` | 符号表与中间代码生成的具体实现（含过程嵌套处理与跳转回填） |
| `calc/` | 一个精简的 Flex/Bison 计算器示例，仅作参考，与 PL/0 编译器本身无关 |

由 Flex/Bison 自动生成的 `.c`/`.h`/`.output` 文件及编译产物不纳入版本库（见 `.gitignore`），需要时按下面的步骤重新生成。

## 实现思路

1. **词法层（`mylex.l`）**——用正则表达式识别每个关键字/运算符/数字/标识符，打印并 `return` 给语法分析器，同时把内容存入 `yylval`。

2. **语法层（`myyacc.y`）**——分两部分：声明部分（常量/变量/过程声明，登记进符号表）和语句部分（赋值/if/while/call/read/write，从符号表查找并生成中间代码）。

3. **符号表与中间代码生成（`MakeInterCode.h`/`.c`）**——自行设计的指令集（`lit/lod/sto/cal/opr/ict/jmp/jpc/ret`），模仿经典 PL/0 的 P-code，并额外处理了两个难点：
   - **过程嵌套作用域**，用 `level` 计数器加每层保存的状态（`endIndex[]` / `blockLength[]`）处理。
   - **跳转回填**——`if`/`while`/程序块入口的跳转先写占位地址，等真实目标地址确定后由 `backPath()` 回填。

## 编译

```sh
flex -o mylex.c mylex.l
bison -d -o myyacc.c myyacc.y
gcc mylex.c myyacc.c MakeInterCode.c -o pl0c
```

运行生成的可执行文件后：选 1 输入源文件路径，选 2 进行词法+语法分析，选 3 查看生成的中间代码。

## PL/0 语法（简化 BNF）

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
