%{
    /*
     *  一个简单计算器的Lex词法文件 / Lex source for a minimal calculator (classic bison/flex tutorial example)
     */
    #include <stdlib.h>

    void yyerror(char*);
  /*  #include "calc.tab.h"  */
%}
%%
    /* a-z为变量 / a-z are treated as single-letter variables */
[a-z]    {
        yylval = *yytext - 'a';
        return VARIABLE;
    }
    /* 整数 / integer literal */
[0-9]+    {
        yylval = atoi(yytext);
        return INTEGER;
    }
    /* 运算符 / operators */
[-+()=/*\n]    {return *yytext;}
    /* 空白被忽略 / whitespace is ignored */
[ \t]    ;
    /* 其他字符都是非法的 / anything else is invalid */
.    yyerror("无效的输入字符");
%%
int    yywrap(void)
{
    return 1;
}
