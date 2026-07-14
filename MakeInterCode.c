#include "MakeInterCode.h"

//符号表数组 / the symbol table array
SymbolTable NameTable[MAXTABLE];
//符号表指针 / next free slot in the symbol table
int tIndex=0;
//当前已经声明的分程序块数量 / current nesting level (-1 = not yet in the main block)
int level=-1;
//分程序块块在符号表中终止地址的索引 / per-level saved symbol-table end index (for restoring on BlockEnd)
int endIndex[MAXLEVEL];
//每个栈需要分配空间记录 / per-level saved frame size (for restoring on BlockEnd)
int blockLength[MAXLEVEL];
//当前栈的相对指针,用于指示对应程序段需要分配的长度 / next free offset within the current block's frame
int localAddr;
//回填指针，用于知晓当前程序段参数个数后，在符号栈中回填参数个数 / symbol-table index of the enclosing procedure, used to backpatch its parameter count
int tempIndex;

//定义三元式 / the generated intermediate-code array
Stack Code[MAXCODE];
int cIndex=-1;//当前代码栈指针 / current code-stack pointer






/*******************************************处理符号表 / symbol-table handling********************************************/

/***注意，这一些函数不用于产生中间码，这些函数用于产生符号表***/
/*** English: these functions only build the symbol table, they don't emit code ***/
/***真正产生中间码是在声明规约结束后，由genCodeOne()产生需要开辟空间的中间代码***/
/*** English: the actual frame-allocation instruction is emitted by genCodeOne() only after the declaration list finishes reducing ***/

/**这个函数用于记录符号表中一个新的程序段的声明段中有哪些新变量名，真正产生中间代码需要等到声明部分递归结束开始****/
/** English: called when entering a new block; sets up bookkeeping so new names get registered under this level; actual code generation for the frame happens only after the declaration list finishes reducing **/
void  BlockBegin(int levebase)
{
	
	if(level==-1)//如果当前是主程序段 / entering the outermost (main) block
	{	
			level++;
			tIndex=0;//符号表的指针初始化 / reset the symbol-table pointer
			localAddr=levebase; //当前程序段需要开辟空间计数器默认2（即在数据堆栈默认至少开辟三个空白区域) / start the frame offset after the 3 reserved header slots
			return  ;//处理终止,初始化成功 / done
	}
	else if(level==MAXLEVEL-1)//如果已经嵌套了了MAXLEVEL多个程序段,弹出错误提示 / nesting limit reached, report an error
	{
		yyerror("语法错误:程序段嵌套超过5层!");//编译终止 / abort - too many nested blocks
	}
	
	//printf("!!!!!!!!!!!!!%d",level);
	//其他情况：即分程序声明段 / otherwise: entering a nested sub-block
	//保存上一段内容 / save the enclosing block's state so it can be restored later
	endIndex[level]=tIndex;//首先保存下一个程序段的首地址 / save where the enclosing block's symbols end
	blockLength[level]=localAddr;//保存该段需要分配的长度 / save the enclosing block's frame size
	//printf("!!!!!!!!!!!!%d,%d",level,localAddr);//测试代码
	//初始化下一段 / initialize the new (inner) block
	localAddr=levebase;//默认至少分配三个 / start offset after the reserved header slots
	level++;//开启下一段 / step down into the new level
	return ;//初始化成功 / done
}

//程序段终止时恢复到上一段 / restore the enclosing block's state when a block ends
void BlockEnd()
{
	level--;//返回到上一段,用于上一段产生代码 / step back up to the enclosing level
	tIndex=endIndex[level];//上一段终止地址 / restore its symbol-table end index
	localAddr=blockLength[level];//上一段所需空间 / restore its frame size
}


//将关键字名称写入符号表 / write a raw name into the next free symbol-table slot
int enterName(char *name)
{
	
	if(tIndex<MAXTABLE)//如果还有剩余空间 / space available
	{
		strcpy(NameTable[tIndex].name,name);
		
	}
	else//否则 / otherwise
	{
		yyerror("语法错误:定义了太多的变量");//abort - too many symbols defined
	}
	return tIndex;
}
//将变量写入符号表 / register a variable in the symbol table
int enterVar(char *Name)
{
	enterName(Name);//填充关键字名称 / write the name
	NameTable[tIndex].kind=varID;//填充类型 / mark it as a variable
	NameTable[tIndex].content.addr.level=level;//填充当前所在程序段 / record its nesting level
	NameTable[tIndex].content.addr.addr=localAddr;//填充相对偏移 / record its offset within the frame
	localAddr++;//已经分配空间增加 / this variable consumes one frame slot
	tIndex++;//指针移动到下一个位置 / advance the symbol-table pointer
	return tIndex;
}
//将常量写入符号表 / register a constant in the symbol table
int enterConst(char *Name,int values)
{
	//这里程序块开辟单元个数不增加，因为产生中间代码时直接将常量的值存入三元式中,不需要额外空间保存 / no frame slot needed - the value is inlined directly into the code
	enterName(Name);
	NameTable[tIndex].kind=constID;//填充类型 / mark it as a constant
	NameTable[tIndex].content.value=values;//填充值 / store its value
	tIndex++;//指针移动到下一个位置 / advance the symbol-table pointer
	//但是分配空间不增加 / frame size is unaffected
	return tIndex;
}
//将程序段的参数存入符号表 / register a procedure parameter
int enterPar(char *Name)
{
	enterName(Name);
	NameTable[tIndex].kind=parID;//填充类型 / mark it as a parameter
	NameTable[tIndex].content.addr.level=level;
	NameTable[tIndex].content.addr.addr=localAddr;//填充相对偏移 / record its offset
	localAddr++;//已经分配空间增加 / consumes one frame slot
	//特别注意，程序段参数个数增加 / bump the enclosing procedure's parameter count
	NameTable[tempIndex].content.procInfo.parNums++;
}

//将程序段的段名填入符号表 / register a procedure name
int enterProc(char *Name,int v)
{
	enterName(Name);
	NameTable[tIndex].kind=procID;//mark it as a procedure
	NameTable[tIndex].content.procInfo.addr.level=level;
	NameTable[tIndex].content.procInfo.addr.addr=v;//填充程序应该在三元式中的起始地址 / record its entry address in the code array
	NameTable[tIndex].content.procInfo.parNums=0;//初始化为0 / parameter count starts at 0
	//注意，保存一下当前程序段在符号表中的起始地址 / remember this entry's index so enterPar() can find it later
	tempIndex=tIndex;
}
//寻找符号表中对应内容 / look up a name in the symbol table, searching innermost scope outward
int searchTable(char *name,Kind kinds)
{
	int i=tIndex;
	int location=-1;
	for(i=tIndex;i>=0;i--)//向上寻找 / search backwards, so inner-scope names shadow outer ones
	{
		printf("XXXXXXXXXX,%s,XXXXXXXXXXXX",NameTable[i].name);
		if(strcmp(name,NameTable[i].name)==0)
		{
			if(location==-1)
			{
				location=i;
				break;
			}
			else if(location!=-1)//如果location不是第一次赋值
			{
				yyerror("语法错误:有同名变量,请重新定义!");//abort - duplicate name
				return -1;
			}
		}
	}
	//printf("XXXXXXXXXXXX%dXXXXXXXXXXXXX",location);
	if(location!=-1)//如果已经找到
	{
		return location;
	}
	else if(location==-1)//如果没有找到 / not found
	{
		yyerror("语法错误:出现未初始化变量!");//abort - use of an undeclared identifier
		return -1;
	}
}
//返回关键字类型，通用 / return a symbol-table entry's kind
Kind returnKind(int i)
{
	return NameTable[i].kind;
}

//给变量用，返回变量的地址 / return a variable's address
RealAddr returnAddr(int i)
{
	return NameTable[i].content.addr;
}

//给常量用，返回常量的值 / return a constant's value
int returnVal(int i)
{
	return NameTable[i].content.value;
}
//给函数用，返回参数个数 / return a procedure's parameter count
int returnPars(int i)
{
	return NameTable[i].content.procInfo.parNums;
}

//给函数用，返回需要开辟空间的个数 / return the current block's required frame size
int returnFrame()
{

	return localAddr;
}
//给函数用，返回当前函数所在的嵌套层数 / return the current nesting level
int returnLevel()
{
	return level;


}
//返回上一层参数数量 / return the enclosing level's saved symbol-table end index
int returnFCodeAddr()
{

	return endIndex[level-1];

}

/*************************************************生成中间代码 / intermediate-code generation********************************************/

//返回下一条堆栈地址 / return the next free code-stack address
int nextCode()
{
	return cIndex+1;
}
//检查当前栈是否还有剩余.如果有，中间代码段指针指向下一个空间 / advance the code pointer if there's room left
void checkMax()
{
	if(cIndex<MAXCODE-1)
	{
		cIndex++;
		return ;
	}
	else//如果当前站没有空间了 / otherwise the code stack is full
	{
		yyerror("编译终止:代码过长，没有空间可以存放!");//abort - out of code-stack space
	}
}

//产生一元地址码，其中包括int,jmp,jpc他们只需要填充一个内容, / emit a one-operand instruction (ict/jmp/jpc, which need only a single value)
//注意：不包括运算符，因为要记录运算符类型 / excludes opr, which stores an operator type instead
int genCodeOne(Instruct opts,int ct)
{
	checkMax();
	Code[cIndex].instr=opts;//指令 / the opcode
	Code[cIndex].content.value=ct;//需要填充的内容 / its operand value
	return cIndex;
}
//产生二元地址码，其中包括cal,lod,sto，注意不包括ret / emit an address instruction (cal/lod/sto), excludes ret
int genCodeTwo(Instruct opts,int i)
{
	checkMax();
	RealAddr temp;
	Code[cIndex].instr=opts;//指令 / the opcode
	temp=returnAddr(i);//在符号表寻找地址 / look up the target's address
	Code[cIndex].content.realaddr.level=level-temp.level;//取值地址=当前层差-所在层层差 / level diff = current nesting level - the target's declared level
	Code[cIndex].content.realaddr.addr=temp.addr;//偏移量保持不变 / offset stays the same
	return cIndex;
}
//产生一元地址码中的运算码，传入的是运算符类型(注意：read,write指令也属于此列_) / emit an opr instruction for the given operator (read/write are treated as operators too)
int genCodeOpt(Opt type)
{
	checkMax();
	Code[cIndex].instr=opr;
	Code[cIndex].content.optr=type;
	return cIndex;
}

//产生而原地址码中的跳转码ret / emit the ret instruction that ends a block
int genCodeReturn(Instruct inst)
{
	//如果函数里面已经写好了return语句 / an explicit return statement already emitted a ret
	if(Code[cIndex].instr==ret)
	{
		return cIndex;//什么不用做 / nothing more to do
	}
	else//如果没有写return语句，或者遇到了return语句，为该函数填充跳转 / otherwise emit the implicit end-of-block ret
	{
		checkMax();
		Code[cIndex].instr=inst;
		Code[cIndex].content.realaddr.level=returnLevel();//当前函数嵌套层数 / the current nesting level
		Code[cIndex].content.realaddr.addr=0;//默认是0，实际由运行时display栈决定 / placeholder, resolved by the runtime display stack
	}
}
//拉链回填 / backpatch a previously emitted jump: fill in the real target address now that it's known
void  backPath(int i)
{
	//printf("!!!!!!!!XXXXXXXXXX %d　xxxxxx!!!!!!",i);
	Code[i].content.value=cIndex+1;
}
//显示中间代码 / print the generated intermediate code
void ShowInterCode()
{

	int i=0;
	printf("\n*************************中间代码显示***********************\n");
	for(i=0;i<=cIndex;i++)
	{
		printf("(%d)	",i);//输出中间码的行号 / print the instruction index
		switch(Code[i].instr)
		{
			
			case lit: 	printf("lit  0  %d \n", Code[i].content.value); break;
			case lod:	printf("lod  %d  %d \n", Code[i].content.realaddr.level, Code[i].content.realaddr.addr); break;
			case sto:	printf("sto  %d  %d \n", Code[i].content.realaddr.level, Code[i].content.realaddr.addr); break;
			case cal:	printf("cal  %d  %d \n", Code[i].content.realaddr.level, Code[i].content.realaddr.addr); break;
			case opr:   printf("opr  0  %d \n", Code[i].content.optr); break;
			case ict:	printf("int  0  %d \n", Code[i].content.value); break;
			case jmp:	printf("jmp  0  %d \n", Code[i].content.value); break;
			case jpc:   printf("jpc  0  %d \n",	Code[i].content.value); break;
			case ret:	printf("ret  %d  %d \n", Code[i].content.realaddr.level, Code[i].content.realaddr.addr); break;
			default:printf("%d not found! \n",Code[i].instr); break;
		}
	}
}



