%{
#ifndef MYLEX_H
#define MYLEX_H
#include <stdio.h>
#include <string.h>
#include "myyacc.h"
#endif
int count;//总字符个数 / total token count
char *names;//变量名 / buffer holding the text of the current token
%}

null		 null
VAR			 var
CONST		 const
BEGINS		 begin
END			 end
IF			 if
ELSE		 else
THEN		 then
WHILE		 while
DO			 do
WRITE		 write
READ		 read
CALL		 call
PROCEDURE	 procedure
RETURN       return 

plus  		 \+
minus 		 \-
mul			 \*
divs          \/
ODD 		 odd

closeq		:=
eq			=
le			<=
re			>=
lt			<
rt			>
neq			#


Consts		 [0-9]+
Delimiter	 [,\;()]
Indentfier   [A-Za-z]([A-Za-z0-9])* 




%option yylineno


%%
{null}				{
					count++;
					yylval.val=0;
					printf("null	");
					return null;
					}
{VAR}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("VAR	");
					return VAR;
					}
{CONST}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("CONST	");		
					return CONST;
					}
{BEGINS}			{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("BEGINS	");		
					return BEGINS;
					}
{END}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("END	");
					return END;
					}
{IF}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("IF	");
					return IF;
					}
{ELSE}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("ELSE	");
					return ELSE;
					}
{THEN}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("THEN	");
					return THEN;
					}
{WHILE}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("WHILE	");
					return WHILE;
					}
{DO}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("DO	");
					return DO;
					}	
{WRITE}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("WRITE	");
					return WRITE;
					}		
{READ}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("READ	");
					return READ;
					}								
{CALL}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("CALL	");
					return CALL;
					}	
					
{PROCEDURE}			{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("PROCEDURE	");
					return PROCEDURE;
					}
{PROCEDURE}			{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("RETURN	");
					return RETURN;
					}
					
{plus}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("plus	");
					return plus;
					}	
{minus}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("minus	");
					return minus;
					}
{mul}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("mul	");
					return mul;
					}
{divs}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("divs	");
					return divs;
					}
					
{closeq}			{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("closeq	");
					return closeq;
					}
{eq}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("eq	");
					return eq;
					}
{le}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("le	");
					return le;
					}
{re}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("re	");
					return re;
					}
{lt}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("lt	");
					return lt;
					}
{rt}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("rt	");
					return rt;
					}	
{neq}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("neq	");
					return neq;
					}
{ODD}				{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("ODD	");
					return ODD;
					}	
					



					
{Consts}			{count++;
					yylval.val=atoi(yytext);
					printf("Consts	");					
					return Consts;
					/*整形数字 / integer literal*/}					
{Indentfier}		{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("Indentfier	");					
					return Indentfier;			
					/*变量 / identifier*/}
{Delimiter}			{count++;
					names=(char*)malloc(strlen(yytext)+1);
					strcpy(names,yytext);
					yylval.name=names;
					printf("Delimiter	");	
					return yytext[0];//返回具体的分界符供bison分析，注意不要返回Delimiter,否则要修改我的bison代码
					// Return the literal delimiter char itself (not the Delimiter token) so bison can match it directly; returning Delimiter would require changing the grammar.
					/*分界符 / delimiter*/}
[ \t\n\r]			{
						if(yytext[0]=='\n')
							printf("\n");
					}
.					{
					//printf("\n******CODEND********	");
					return yytext[0];
					}
%%

/*************主函数测试 / standalone test main (unused, kept for reference)*****************/
/*
void main()
{
	yyin=fopen("D://EXAMPLE.txt","r");
	yylex();
	system("PAUSE");/*暂停,  使DOS窗口停住 / pause so the console window does not close immediately*/
//}

