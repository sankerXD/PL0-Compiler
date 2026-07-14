#ifndef MakeCode_H
#define MakeCode_H
#include <stdio.h>
#include <string.h>

/*************整个中间代码设计思路 / Overall design of intermediate-code generation*********/
/* 1.变量，常量，程序段名称放入符号栈中,这些规约函数一律以interxxxx命名*/
/*    English: names of variables/constants/procedures go into the symbol table; these helper functions are named enterXXX() */
/* 2.规约过程中根据符号栈内容填写中间代码栈，这些规约函数一律以genxxx命名*/
/*    English: while reducing, symbol-table entries are used to emit instructions into the code stack; these helpers are named genXXX() */
/* 3.输出中间代码到文件*/
/*    English: the generated intermediate code can be printed out */
/* 4.用一个全局活动记录表display记录程序段的地址，用stack保存栈的运行值*/
/*    English: a global display/activation-record table tracks block addresses; a runtime stack holds values */
/* 5.注意：和书上不一样的一点在于书上返回指令用opr 0 0代表，我用ret L A代表，这样子更清楚层差，运行原理是一样的*/
/*    English: unlike the textbook (which encodes "return" as opr 0 0), this project uses a dedicated ret L A instruction so the level difference is explicit; the runtime behaviour is otherwise identical */


/************指令集 / instruction set*************/
typedef enum instrs
{
	/* lit:将常数放到栈顶;lod:将变量到栈顶;sto:将栈顶内容送入变量;cal:过程调用指令;
	***opr：关系运算符与算术运算符;ict:为过程块开辟指定数目的空间（由于编译器的宏定义问题这里无法写作int);
	***jmp:无条件跳转;jpc:相等时跳转;ret:这里改进了一条指令,用于return语句*/
	/* English: lit=push constant, lod=push variable, sto=pop into variable, cal=call procedure,
	***         opr=relational/arithmetic op, ict=reserve N stack slots for a frame (named ict, not int, to avoid the C keyword clash),
	***         jmp=unconditional jump, jpc=jump if top-of-stack is 0/false, ret=custom instruction added for explicit return handling */
	lit,lod,sto,cal,opr,ict,jmp,jpc,ret
}Instruct;

/***********算术运算与逻辑运算操作符 / arithmetic & logical operators****************/
typedef enum optor
{
	/*    =,#,<,>,<=,>=,odd,+,-,*,/  从控制台读，写出到控制台  */
	/* English: comparison/arithmetic ops, plus read (from stdin) and write (to stdout) */
	/*注意这里的's'仅仅为了避免myyacc.y中已经定义的单词重名'*/
	/* English: the leading 's' prefix (seq, slt, ...) just avoids clashing with token names already defined in myyacc.y */
	sodd,splus,sminus,smul,sdiv,seq,sneq,slt,srt,sle,sre,neg,read,write
}Opt;





/**********!!!!!!!!!!!!!定义!!!!!!!!!!!!!!!!!*************/

/****************起始地址:=块地址+块的偏移地址 / an address = block(nesting-level) address + offset within that block************/
typedef struct location
{
	int level;//块地址 / nesting level of the block
	int addr;//相对地址 / offset relative to the start of that block
}RealAddr;


/********!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!定义符号表 / symbol table definition!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!**************/
//符号表最大表长300 / max number of symbol-table entries
#define MAXTABLE 300
//符号最大长度30 / max length of an identifier
#define MAXNAME  30
//栈基质为第三个，标识符写为2 / stack base starts at slot 3 (index 2)
#define StackBase 2
//程序块最多嵌套的块数 / max nesting depth of procedure blocks
#define MAXLEVEL 5

//符号表中符号类型:变量(var),常量(const),参数(par),函数 / kinds of symbol-table entries: variable, constant, parameter, procedure
typedef enum KIND
{
	constID,varID,parID,procID
}Kind;

//符号表 / the symbol table entry itself
typedef struct SymbolTable
{
	char name[MAXNAME];
	Kind kind;
	union
	{
		int value;//常量:值 / constant: its value
		//程序段:有地址和参数个数 / procedure: entry address and parameter count
		struct
		{
			RealAddr addr;//程序地址 / procedure entry address
			int parNums;//参数个数 / number of parameters
		}procInfo;
		//变量:地址 / variable: its address
		RealAddr addr;
	}content;
}SymbolTable;



//特别注意这个：这个是为了创建代码时在每个程序段头空出3个空白堆栈（地址是3-1=2），这三个空白堆栈用于其他内容
// English: reserves 3 slots (offsets 0-2) at the head of every block/procedure frame for runtime bookkeeping (the classic PL/0 activation-record header - return value / dynamic link / static link); user data starts at offset 3
#define levelbase 3


/***************************************定义中间代码堆栈 / intermediate-code stack definition**************************************************/

/*************所有运算均在栈顶和次栈顶完成，因此关系运算符无需指出所在真实位置********/
/* English: all arithmetic/relational ops act on the top two stack values, so op codes need no address operand */
/**********每一层的结构: |操作符|地址(层差)|操作符在符表中的数值 *********/
/* English: each code entry layout: | opcode | address (level diff) | operand / symbol-table value | *********/
typedef struct layer
{
	Instruct instr;//指令
	union
	{
		RealAddr realaddr;//如果是取数存数指令，用于指定变量的地址（层差+相对偏移)
		int value;//如果是常量，value用于保存数值;如果是转移指令，表明中间码的地址
		Opt optr;//如果是运算符，表明运算符类型
	}content;
}Stack;

/******代码堆栈的最大长度 / max length of the code stack********/
#define MAXCODE 400 
/******运算栈最大长度 / max length of the runtime evaluation stack*********/
#define MAXMEMORY 4000 
/******运算栈顶最大利用长度 / max usable depth near the stack top*****/
#define MAXRANGE 20



void BlockBegin(int levebase);//程序段分配空间开始 / start allocating a new block's frame
void BlockEnd();//程序段分配空间终止 / finish/pop a block's frame
int enterName(char *name);//将关键字名称写入符号表 / write a raw name into the symbol table
int enterVar(char *Name);//将变量写入符号表 / register a variable
int enterConst(char *Name,int values);//将常量写入符号表 / register a constant
int enterPar(char *Name);//将程序段的参数存入符号表 / register a procedure parameter
int enterProc(char *Name,int v);//将程序段的段名填入符号表 / register a procedure name
int searchTable(char *name,Kind kinds);//寻找符号表中对应内容 / look up an entry in the symbol table
Kind returnKind(int i);//返回关键字类型，通用 / return the kind of a symbol-table entry
RealAddr returnAddr(int i);//给变量用，返回变量的地址 / return a variable's address
int returnVal(int i);//给常量用，返回常量的值 / return a constant's value
int returnPars(int i);//给函数用，返回参数个数 / return a procedure's parameter count
int returnFrame();//给函数用，返回需要开辟空间的个数 / return the frame size a block needs

int nextCode();//返回下一条代码堆栈地址 / return the next free code-stack address
void checkMax();//检查当前栈是否还有剩余.如果有，中间代码段指针指向下一个 / check remaining code-stack space and advance the pointer
int genCodeOne(Instruct opts,int ct);//产生一元地址码,运算码除外 / emit a one-operand instruction (excludes opr)
int genCodeTwo(Instruct opts,int i);//产生二元地址码,ret跳转码除外 / emit an address instruction (level+offset), excludes ret
int genCodeOpt(Opt type);//产生一元地址码中的运算码 / emit an opr instruction
int genCodeReturn(Instruct inst);//产生跳转码ret的跳转地址 / emit the ret instruction for a block
void  backPath(int i);//拉链回填 / backpatch a previously emitted jump
void ShowInterCode();//显示中间代码 / print the generated intermediate code
#endif