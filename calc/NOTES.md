# calc example / calc 示例说明

flex 文件: `flex.exe` (or the `flex` binary on Linux/macOS)
bison 文件: `bison.exe` (or the `bison` binary on Linux/macOS)

Build steps / 编译步骤:

1. `flex -o lexyy.c calc.lex`
2. `bison -o calc.c calc.y`
3. Compile and run `calc.c` / 编译运行 `calc.c`

## bison 编译说明 / Bison notes

In the `.y` source, add near the top:
在编写 bison 源程序中，需要在开始部分添加:

```c
#define __STDC__ 0
```

Before `main()`, add an error handler and hook up the generated lexer:
在 main 函数前添加出错处理函数，并引入生成的词法分析代码:

```c
void yyerror(char* s)
{
    fprintf(stderr, "%s\n", s);
}
#include "lexyy.c"
int main(void)
{
    yyparse();
}
```

## flex 编译说明 / Flex notes

The `.l` source needs an end-of-input handler:
编写 flex 源程序时，需要增加如下代码:

```c
int yywrap(void)
{
    return 1;
}
```

If used standalone (without bison), add a `main()`:
如果单独使用应添加主函数:

```c
main() {
    yylex();
}
```

Name the generated C file `lexyy.c` so it matches the `#include` in the bison file:
注意将编译生成的 C 文件命名为 `lexyy.c`，与 bison 文件中的 `#include` 对应:

```
flex -o lexyy.c calc.lex
```
