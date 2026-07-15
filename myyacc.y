%union{
	char *name;
	int val;
}

//头定义 / header & type declarations
%{

#ifndef MYYACC_H
#define MYYACC_H
#include <stdio.h>
#include <stdlib.h>
#include "MakeInterCode.h"
#endif
void yyerror(char *s);
int  yywrap(void);
%}

//终结符声明 / terminal symbol declarations
%token null VAR CONST BEGINS END IF ELSE THEN WHILE DO WRITE READ CALL PROCEDURE RETURN
%left plus minus mul divs
%left closeq neq eq
%left le re lt rt ODD
%token Consts  Indentfier Delimiter 

%token <val> Consts
%token <name> Indentfier




//规约声明->程序::=块.
//块::=变量定义 程序块
//变量定义::=变量:=数值
//程序块::=标记 状态
// English: program -> block ; block -> declarations statements ;
// declarations bind names in the symbol table, statements consume them.

%%
program:  			{	printf("\n>>>>使用产生式规则:program->block\n");  
						BlockBegin(levelbase);
					}
		block
		;
		
block 	: 		 {$<val>$=genCodeOne(jmp,0);/*先写个0防止出错，下面backPath函数才是jmp真正的地址 / emit a placeholder jmp 0; backPath() below fills in the real target address*/}
		declList  { 
					printf("\n>>>>使用产生式规则:block->declList\n ");
					backPath($<val>$) ;//回填跳转地址,必须在开辟空间前回填，否则指针移动到开辟空间代码的下一条 / backpatch the jump target now, before the space-allocation (ict) instruction, otherwise the code pointer will have already moved past it
					genCodeOne(ict,returnFrame());/*获取需要开辟的空间 / allocate the stack frame space this block needs*/ 
					//printf("\n!!!!! %d",returnFrame());//测试代码
					
				  }
		stateList {	
					printf("\n>>>>使用产生式规则:block->stateList\n ");
					genCodeReturn(ret);//填充结束时跳转的地址 / fill in the return-jump address
					BlockEnd();/*结束当前递归层 / pop back out of the current nesting level*/
				  }
		;
		
//声明 / declarations
declList : /*空*/
		| declList decl
		;
//三种声明 / three kinds of declarations: const, var, procedure
decl	: constDecl  
					 {	
						printf("\n>>>>使用产生式规则:block->constDecl\n "); 
					 }
		| varDecl    
					{	
						printf("\n>>>>使用产生式规则:block->varDecl \n "); 
					}
		| funcDecl   
					{ 
						printf("\n>>>>使用产生式规则:block->funcDecl \n ");
					} 
		;

//特别注意：常量不需要为他在栈中开辟空间，直接在用到的三元栈中存储即可
// Note: constants need no runtime stack slot - their value is embedded directly in the generated code.
//常量声明 const a=3; / constant declaration, e.g. const a=3;		
constDecl :CONST  numberlist  ';'  
									{ printf("\n>>>>使用产生式规则:constDecl->CONST  numberlist  ';'\n");
									
									}
		  ;

numberlist : Indentfier eq Consts    
									{ printf("\n>>>>使用产生式规则:numberlist->Indentfier eq Consts  ';'\n");
									  enterConst($<name>1,$3);//将变量登记到符号表
									 // printf("XXXXXXXX,%s,XXXXXXXXXX",$<name>1);
									 }
		   | numberlist COMM Indentfier eq Consts
									{ printf(" \n 使用产生式规则:numberlist->numberlist COMM Indentfier eq Consts  ';'\n");
									  enterConst($<name>3,$5);//将变量登记到符号表
									}
		   ;

//变量声明 var ...; / variable declaration, e.g. var a,b;

varDecl	   :VAR  IndentfierList ';'	
									{ 
										printf("\n>>>>使用产生式规则:constDecl->VAR  IndentfierList ';'\n");
									}
			;

IndentfierList : ModeDec 
									{ 
										printf("\n>>>>使用产生式规则:IndentfierList->ModeDec \n");
									}
				|IndentfierList COMM ModeDec
									{ 
										printf("\n>>>>使用产生式规则:IndentfierList->IndentfierList COMM ModeDec \n");
									}
				;
				
//变量声明 var a;; / single variable in a var-list
ModeDec		   :Indentfier	
									{ 
										printf("\n>>>>使用产生式规则:ModeDec->Indentfier \n");
										enterVar($<name>$);
									}
			   ;
			   

//函数声明	两种形式 1.procedure p;procedure p(a,b,c,d/空); / procedure declaration, with or without a parameter list
funcDecl	: PROCEDURE Indentfier 
									{	
										
										$<val>$=genCodeOne(jmp,0);/*先写个0防止出错，下面backPath函数才是jmp真正的地址*/
										BlockBegin(levelbase);
										enterProc($<name>2,nextCode());//填写在三元式中的名字与起始地址 / record the procedure's name and entry address in the code array
										
									} 
			  '(' VarList ')' ';' 
              BEGINS declList 	
								{ 		
										backPath($<val>$);//写在这里是因为VarList递归导致$<val>$发生了变化，而这个是不需要的 / done here because VarList's recursion would otherwise overwrite $<val>$ before we can use it
										genCodeOne(ict,returnFrame());/*获取需要开辟的空间*/ 
										//printf("\n!!!!! %d",returnFrame());//测试到代码	
								}
			  
			  stateList END ';'	
								{	    printf("\n>>>>使用产生式规则:PROCEDURE Indentfier ';' BEGINS declList stateList END ';'	\n ");
										genCodeReturn(ret);//填充结束时跳转的地址
										BlockEnd();/*结束当前递归层*/
								}
			|  PROCEDURE Indentfier ';'					
									  {
										$<val>$=genCodeOne(jmp,0);/*先写个0防止出错，下面backPath函数才是jmp真正的地址*/
										enterProc($<name>2,nextCode());//填写在三元式中的名字与起始地址 / record the procedure's name and entry address in the code array
										BlockBegin(levelbase);
										//backPath($<val>$);
									  } 
			  						  
			  BEGINS declList 
									  { 
										backPath($<val>$) ;//必须写在开辟空间的前面 / must run before the space-allocation instruction
										genCodeOne(ict,returnFrame());/*获取需要开辟的空间*/ 
										//printf("\n!!!!! %d",returnFrame());//测试到代码
										
									  }
			  stateList END ';'
										{	printf("\n>>>>使用产生式规则:PROCEDURE Indentfier ';' BEGINS declList stateList END ';'	\n ");
											genCodeReturn(ret);//填充结束时跳转的地址
										    BlockEnd();/*结束当前递归层*/
										}
			;

			


//许多的变量 a,b,c...//注意这里不能为空，否则会产生移进/规约冲突
// English: parameter list a,b,c,...; must NOT be allowed to be empty here, or it creates a shift/reduce conflict.
VarList		: Indentfier 
						{   
							printf("\n>>>>使用产生式规则:VarList->Indentfier \n");
							enterVar($<name>$);
						}
			| VarList COMM Indentfier 
						{  
							printf("\n>>>>使用产生式规则:VarList->VarList COMM Indentfier  \n");
							enterVar($<name>3);
						}
			;

//','处理 / comma separator		   
COMM	   :','   
		   ;
		   
//状态声明 比如 while /if/取值/输出等，注意，这里不需要加';'，因为在循环链statement里面已经有了
// English: statement forms - while/if/read/write/etc. No trailing ';' is added here since stateList already handles it.
statement	: Assigment 
									{
										printf("\n>>>>使用产生式规则:statement->Assigment\n");
									}
			| READ  		
									{
										printf("\n>>>>使用产生式规则:statement->READ '(' unit ')' \n");
										genCodeOpt(read);//记录操作符,从命令行读入一个数值存入栈顶 / emit the read op: reads a value from stdin and pushes it on the stack
									} 
			'(' Content ')' 
					
			
			| WRITE '(' expression ')'
									{
										printf("\n>>>>使用产生式规则:statement->WRITE '(' expression ')' \n");
										genCodeOpt(write);
									}
			| BEGINS stateList END  
			| 	IF condition THEN 
									{	
										$<val>$=genCodeOne(jpc,0);//先不填跳转地址，后面用拉链回填 / emit jpc with a placeholder target, backpatched later
									}
				statement
									{
										backPath($<val>$);
										printf("\n>>>>使用产生式规则:statement->IF condition THEN statement \n");
										
									}
			| WHILE {
						$<val>$=nextCode();
					}
					condition DO
								{
									 $<val>$=genCodeOne(jpc,0);//先产生这条代码，后面再回填 / emit this instruction now, backpatch the target later 
								}
						statement 
								{
									printf("\n>>>>使用产生式规则:statement->WHILE condition DO statement\n");
									genCodeOne(jmp,$<val>2);//相等时做完对应内容调回开头 / jump back to the condition check after the loop body runs
									backPath($<val>5);//回填相等时跳转地址 / backpatch the loop-exit jump target
								}
					
						
			| CALL Indentfier
								{
									printf("\n>>>>使用产生式规则:statement->CALL Indentfier\n");
									genCodeTwo(cal,searchTable($<name>2,procID));
								}
			| RETURN expression
								{
									printf("\n>>>>使用产生式规则:statement->RETURN expression\n");
									//这里什么代码也不用产生，栈顶保留即可 / no extra code needed here - the return value is simply left on top of the stack
								}
			;

Content	:   Indentfier	
						{
							//这个产生式用于保存变量的值 / this rule stores the just-read value back into the variable
							printf("\n>>>>使用产生式规则:Content->Indentfier\n");
							genCodeTwo(sto,searchTable($<name>$,varID));//将栈顶的值送回变量 / store the top-of-stack value into the variable

						}


			
stateList	: 
			| stateList statement ';' 
			| stateList statement '.' 
			;
	
//赋值语句 / assignment statement
Assigment	: Indentfier closeq expression 
										{
											printf("\n>>>>使用产生式规则:Assigment->Indentfier closeq expression\n");
											genCodeTwo(sto,searchTable($1,varID));
										} 
			;

//比较语句 / condition / comparison expression
condition	: expression	
							{
								printf("\n>>>>使用产生式规则:condition->expression\n");
								genCodeOpt(seq);
							}
			| ODD expression
							{
								printf("\n>>>>使用产生式规则:condition->ODD expression\n");
								genCodeOpt(sodd);
							}
			| expression eq expression
							{
								printf("\n>>>>使用产生式规则:condition->expression eq expression\n");
								genCodeOpt(seq);
							}
			| expression neq expression
							{
								printf("\n>>>>使用产生式规则:condition->expression neq expression\n");
								genCodeOpt(sneq);
							}
			| expression lt expression
							{
								printf("\n>>>>使用产生式规则:condition->expression lt expression\n");
								genCodeOpt(slt);
							}
			| expression rt expression
							{
								printf("\n>>>>使用产生式规则:condition->expression rt expression\n");
								genCodeOpt(srt);
							}
			| expression le expression
							{
								printf("\n>>>>使用产生式规则:condition->expression le expression\n");
								genCodeOpt(sle);
							}
			| expression re expression
							{
								printf("\n>>>>使用产生式规则:condition->expression re expression\n");
								genCodeOpt(sre);
							}
			;
			
//表达式语句 / arithmetic expression
expression	:minus highporList 
							{
								printf("\n>>>>使用产生式规则:expression->neg highporList lowpor\n");
								genCodeOpt(neg);
							}
			    lowpor
			| highporList lowpor
							{
								printf("\n>>>>使用产生式规则:expression->highporList lowpor\n");
							}
			;

//低优先级运算 / low-precedence operators: + and -
lowpor		:/*可以是空的*/
			| lowpor plus highporList
							{
								printf("\n>>>>使用产生式规则:lowpor->lowpor plus highporList\n");
								genCodeOpt(splus);
							}
			| lowpor minus highporList
							{
								printf("\n>>>>使用产生式规则:lowpor->lowpor minus highporList\n");
								genCodeOpt(sminus);
							}
			;

//高优先级运算 / high-precedence operators: * and /			
highporList	:unit highpor
							{
								printf("\n>>>>使用产生式规则:highporList->unit highpor\n");
							}
			;

highpor		:/*可以为空*/
			| highpor mul unit
							{
								printf("\n>>>>使用产生式规则:highpor-> highpor mul unit\n");
								genCodeOpt(smul);
							}
			| highpor divs unit 
							{ 
								printf("\n>>>>使用产生式规则:highpor-> highpor divs unit\n");
								if($<val>3==0) 
									{ yyerror("被除数不能是零!"); return 0;}
								genCodeOpt(sdiv);
							}
			;
			
//高优先级可以是数字,变量,(...) / an operand: a number, an identifier, or a parenthesized expression		
unit 		:Consts 
					{
						printf("!!!!!!!!!!!!!!!!!!!!!!!");
						printf("\n>>>>使用产生式规则:unit-> Consts\n");
						genCodeOne(lit,$1);
					}
			| Indentfier 
					{   
						//注意，这里可能是常量也可能是变量 / note: this identifier could resolve to either a constant or a variable
						int lo,kinds;
						printf("\n>>>>使用产生式规则:unit-> Indentfier\n");
						lo=searchTable($<name>$,varID);//查找位置 / look up its symbol-table index
						kinds=returnKind(lo);//查找类型 / look up its kind (const or var)
						//printf("!!!!!!!!!!!!");
						switch(kinds)
						{
							case constID:{genCodeOne(lit,returnVal(lo));};break;
							case varID:{genCodeTwo(lod,lo);};break;
						}
							
						
						
					}
			| '(' expression ')'
					{  
						printf("\n>>>>使用产生式规则:unit-> '(' expression ')'\n");
						
					}
			;



%%
/**********************全局定义****************/
extern int  yylineno;//行号 / current source line number
extern char *yyin;//文件指针 / input file pointer

/********************分析终止功能**********/
int  yywrap(void)
{
      return 1;
}
/******************错误提示功能*************/
void yyerror(char *s)
{
	printf("\n*******************************错误提示********************************\n");
	printf("%s 出现在源代码 Line%d\n",s,yylineno);
	system("PAUSE");
	exit(0);//编译终止 / abort compilation
}
/*******************主函数*******************/
void main()
{

	
		printf("*******************************************************************\n");
		printf("***								***\n");
		printf("***			PL/0加强版编译器V1			***\n");
		printf("***			Open-sourced PL/0 compiler front-end (Flex + Bison)		***\n");
		printf("***							        ***\n");
		printf("*******************************************************************\n");
	while(1)
	{	
		int i;
		
		printf("******************************功能说明****************************\n");
		printf("1.输入分析文件路径\n");
		printf("2.词法分析与语法分析\n");
		printf("3.显示中间代码\n");
		printf("请输入:");
		scanf("%d",&i);
		if(i==1)
		{
			char path[100];
			printf("请输入源文件所在的绝对路径(请务必输入正确):\n");
			scanf("%s",path);
			yyin=fopen(path,"r");//读取文件
			if(yyin==0)
				printf("无法找到该文件!\n");
		}
		if(i==2)
		{
			printf("***************************词法分析与语法分析*******************\n");
			yyparse();//分析
			printf("****************************分析结束****************************\n");
		}
		if(i==3)
		{
			printf("*****************************中间代码**************************\n");
			ShowInterCode();
			printf("*****************************显示完毕**************************\n");
		}

	}
}
