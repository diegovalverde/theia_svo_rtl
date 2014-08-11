#include "CDeviceManager.hpp"
#include <errno.h>
#include <termios.h>
#include <unistd.h>
#include <stdio.h>
#include <cstring>  //strerror()
#include <sys/types.h>
#include <sys/stat.h>
#include <fcntl.h>
#include <stdlib.h>
#include <bitset>
#include <fstream>
#include <sstream>
#include <iterator>

CDevice *        gCurrentDevice = NULL;
CDeviceManager * gDeviceManager = NULL;
bool             gVerbose = false;
int              gLastReadValue = 0;

//Function forward declarations

vector<string> ParseGTOperation(int aInstructionIndex, string aLine );
void CallBackGtRead( std::vector<string> aArguments);
//-----------------------------------------------------------------------------------
#define AABB_OP(X)         ((X & 0xE00) >> 9)
#define AABB_B(X)          (X&0x7)
#define AABB_A(X)          ((X&0x38) >> 3)
#define AABB_DST(X)        ((X&0x1c0)>>6)

#define AABB_NOP             0x0
#define AABB_MUL             0x1
#define AABB_SUB             0x2
#define AABB_RET_IF_LT       0x3
#define AABB_RET_IF_GT       0x4
#define AABB_ADD             0x5
#define AABB_POP             0x6

#define CNTRL_DEV_RESET_AABBS 0x9
#define GT_MAX_REGS 8
#define RGU_MAX_REGS 32
void PrintInstruction( string aHexValue)
{

	int Insn;
    sscanf(aHexValue.c_str(), "%x", &Insn);
	
	string Operation;
	cout << aHexValue << "\t\t";
	switch ( AABB_OP(Insn))
	{
		case AABB_NOP: 	cout << "NOP "; return;
		case AABB_MUL:	cout << "MUL "; break;
		case AABB_SUB:	cout << "SUB "; break;
		case AABB_ADD:	cout << "ADD "; break;
		case AABB_RET_IF_LT: cout << "RET_IF_LT "; break;
		case AABB_RET_IF_GT: cout << "RET_IF_GT "; break;
		default: cout << "Unknown "; break;
	}
	
	cout << "r" << AABB_DST(Insn) << " r" << AABB_A(Insn) << " r" << AABB_B(Insn) << "\n";
	
	
}

//-----------------------------------------------------------------------------------
string CDeviceManager::GetCurrentDeviceName( void )
{
	return gCurrentDevice->mName;
}
//-----------------------------------------------------------------------------------
void CallBack_SetScopeToParent(vector<string> aArguments )
{
    
    if (gCurrentDevice->mParent == NULL)
       throw string("This is the root of the hierarchy");

    gCurrentDevice = gCurrentDevice->mParent;
    
}
//-----------------------------------------------------------------------------------
void CallBack_SetScopeToChild(vector<string> aArguments)
{
    
    string ChildName = aArguments[1];

    if (ChildName == "..")
        return CallBack_SetScopeToParent(aArguments);

    if (gCurrentDevice->mChild.find(ChildName) == gCurrentDevice->mChild.end())
       throw string("No such child '" + ChildName + "'");

    gCurrentDevice = &gCurrentDevice->mChild[ ChildName ];
	
   
}

//-----------------------------------------------------------------------------------
void  CallBackGtWrite(vector<string> aArguments )
{
    vector<BYTE > Data;
    

    if (aArguments.size() != 3)
        throw string("CallBackGtWrite: Invalid argument count");
		
	if (gCurrentDevice->mActive)
		throw string("Can't write registers while device is running!");

    char RegType = aArguments[1][0];
    string Register = aArguments[1].erase(0,1);

    if (RegType != 'r' &&RegType != 'i')
        throw string("Invalid argument type, expected 'r' or 'i'");


    int RegId,Value;
    sscanf(Register.c_str(), "%x", &RegId);
    sscanf(aArguments[2].c_str(), "%x", &Value);
/*	
    cout << "Value = " << Value << "\n";
    cout << "RegId   = " << RegId << "\n";
    cout << "RegType = " << RegType << "\n";
	*/

    Data.push_back( UART_DEV_WRITE);
    Data.push_back( gCurrentDevice->mId);
    Data.push_back( 0 );
    Data.push_back( (RegType == 'i') ? (RegId | 0x80): RegId );
    Data.push_back( (Value & 0xff000000) >> 24 );
    Data.push_back( (Value & 0x00ff0000) >> 16 );
    Data.push_back( (Value & 0x0000ff00) >> 8  );
    Data.push_back( Value & 0x000000ff );

    gDeviceManager->WriteUart( Data );
	
	if (RegType == 'i')
		PrintInstruction(gDeviceManager->ReadUartWord32());
	else	
		cout <<  gDeviceManager->ReadUartWord32() << "\n"; 
}
//-----------------------------------------------------------------------------------
void CallBackAssert(vector<string> aArguments)
{
	if (aArguments.size() != 3)
        throw string("CallBackAssert: Invalid argument count");
		
	if (gCurrentDevice->mActive)
		throw string("Can't read registers while device is running!");

	vector<string> Args;
	Args.push_back("read");
	Args.push_back(aArguments[1]);
	CallBackGtRead(Args);

	int ExpectedValue = 0;
	sscanf(aArguments[2].c_str(),"%x",&ExpectedValue);
	if (gLastReadValue == ExpectedValue)
		cout << "Assertion passed: ";
	else
		cout << "Assertion failed: ";

	printf("ExpectedValue 0x%x Actualvalue 0x%x\n", gLastReadValue, ExpectedValue);

}
//-----------------------------------------------------------------------------------
void CalllBackiWrite(vector<string> aArguments)
{

   if (aArguments.size() != 6)
        throw string("CallBackGtiWrite: Invalid argument count");
		
	if (gCurrentDevice->mActive)
		throw string("Can't write registers while device is running!");

	string Line;
	for (int i = 2; i < aArguments.size(); i++)
	{
		Line += aArguments[i] + " ";
	}
	int InstructionIndex;
	sscanf(aArguments[1].c_str(), "%x", &InstructionIndex);
	vector<string> Arguments = ParseGTOperation(InstructionIndex,Line);
	CallBackGtWrite(Arguments);
}
//-----------------------------------------------------------------------------------
void CallBackLoadScript(vector<string> aArguments)
{
	if (aArguments.size() != 2)
        throw string("CallBackLoadAABBProgramFile: Invalid argument count");
		
	gDeviceManager->LoadScript(aArguments[1]);
}
//-----------------------------------------------------------------------------------
void CDeviceManager::LoadScript( string aPath )
{

	ifstream ifs(aPath.c_str());
	if (!ifs.good())
		throw string("Could not open file '") + aPath + "'";
	
	while (ifs.good())
	{
		vector<string> Arguments;
		string Line;
		std::getline( ifs,Line );
		if (Line.find("//") != string::npos)
			Line.erase(Line.find("//"),Line.size());
			
		stringstream ss(Line);
		std::istream_iterator<string> begin(ss);
		std::istream_iterator<string> end;
		vector<string> Tokens(begin, end);
		
		
		SendCommandToActiveDevice(Tokens);
		
		if (Line.size() == 0 )
			continue;	
			
	}
	ifs.close();	
}
//-----------------------------------------------------------------------------------
vector<string> ParseGTOperation(int aInstructionIndex, string aLine )
{
	cout << aLine << "\n";
	vector<string> Arguments;
	map<string,int> OperationType;
	OperationType["nop"] = AABB_NOP;
	OperationType["mul"] = AABB_MUL;
	OperationType["sub"] = AABB_SUB;
	OperationType["add"] = AABB_ADD;
	OperationType["ret_if_lt"] = AABB_RET_IF_LT;
	OperationType["ret_if_gt"] = AABB_RET_IF_GT;
	OperationType["stop"]      = AABB_NOP;

	map<string,int>  RegId;
	for (int i = 0; i < 8; i++)
	{
		char Reg[32];
		sprintf(Reg,"r%d",i);
		RegId[string(Reg)] = i;
	}
	

	stringstream ss;
		ss << aLine;
		string Operation , Destination, OperandA, OperandB;
		ss >> Operation >> Destination >> OperandA >> OperandB;
		//cout << "*** " << Operation << " " << Destination << " " << OperandA << " " << OperandB << "\n";
		
		if (OperationType.find( Operation ) == OperationType.end())
			throw string(" Unknown operation '") + Operation  + "'";
		
		if (Operation == "nop" || Operation == "stop")
		{
			Destination = "r0";
			OperandA = "r0";
			OperandB = "r0";
		}
		else
		{
			if ( RegId.find( Destination ) == RegId.end())
				throw string(" Unknown register '") + Destination  + "'";

			if (RegId.find( OperandA ) == RegId.end())
				throw string(" Unknown register '") + OperandA  + "'";

			if (RegId.find( OperandB ) == RegId.end())
				throw string(" Unknown register '") + OperandB  + "'";
		}

			
		char InsnId[32],InsnData[32];
		sprintf(InsnId,"i%d",aInstructionIndex);
		Arguments.push_back("write");
		Arguments.push_back(string(InsnId));
		
		int Int16 = (OperationType[ Operation ] << 9) | (RegId[Destination] << 6) | (RegId[OperandA] << 3) | RegId[OperandB];
		if (Operation  == "stop")
			Int16 = 0x8000;
			
		sprintf(InsnData, "0x%04x", Int16);
		
	
		Arguments.push_back(string(InsnData));
		PrintInstruction(InsnData);

		return Arguments;

}
//-----------------------------------------------------------------------------------
void CallBackLoadAABBProgramFile(vector<string> aArguments)
{
	#if 0
	if (aArguments.size() != 2)
        throw string("CallBackLoadAABBProgramFile: Invalid argument count");
		
	ifstream ifs(aArguments[1].c_str());
	if (!ifs.good())
		throw string("Could not open file '") + aArguments[1] + "'";
		
	map<string,int> OperationType;
	OperationType["nop"] = AABB_NOP;
	OperationType["mul"] = AABB_MUL;
	OperationType["sub"] = AABB_SUB;
	OperationType["add"] = AABB_ADD;
	OperationType["ret_if_lt"] = AABB_RET_IF_LT;
	OperationType["ret_if_gt"] = AABB_RET_IF_GT;
	OperationType["stop"]      = AABB_NOP;
	
	map<string,int>  RegId;
	for (int i = 0; i < 8; i++)
	{
		char Reg[32];
		sprintf(Reg,"r%d",i);
		RegId[string(Reg)] = i;
	}
	
	
	int i = 0;
	while (ifs.good())
	{
		vector<string> Arguments;
		string Line;
		std::getline( ifs,Line );
		if (Line.size() == 0)
			continue;
			
		stringstream ss;
		ss << Line;
		string Operation , Destination, OperandA, OperandB;
		ss >> Operation >> Destination >> OperandA >> OperandB;
	//	cout << "*** " << Operation << " " << Destination << " " << OperandA << " " << OperandB << "\n";
		
		if (OperationType.find( Operation ) == OperationType.end())
			throw string(" Unknown operation '") + Operation  + "'";
		
		if (Operation == "nop" || Operation == "stop")
		{
			Destination = "r0";
			OperandA = "r0";
			OperandB = "r0";
		}
		else
		{
			if ( RegId.find( Destination ) == RegId.end())
				throw string(" Unknown register '") + Destination  + "'";

			if (RegId.find( OperandA ) == RegId.end())
				throw string(" Unknown register '") + OperandA  + "'";

			if (RegId.find( OperandB ) == RegId.end())
				throw string(" Unknown register '") + OperandB  + "'";
		}

			
		char InsnId[32],InsnData[32];
		sprintf(InsnId,"i%d",i++);
		Arguments.push_back("write");
		Arguments.push_back(string(InsnId));
		
		int Int16 = (OperationType[ Operation ] << 9) | (RegId[Destination] << 6) | (RegId[OperandA] << 3) | RegId[OperandB];
		if (Operation  == "stop")
			Int16 = 0x8000;
			
		sprintf(InsnData, "0x%04x", Int16);
		
	
		Arguments.push_back(string(InsnData));
		PrintInstruction(InsnData);
		
		CallBackGtWrite(Arguments);
		
		
		
	}
	ifs.close();
	#else
	if (aArguments.size() != 2)
        throw string("CallBackLoadAABBProgramFile: Invalid argument count");
		
	ifstream ifs(aArguments[1].c_str());
	if (!ifs.good())
		throw string("Could not open file '") + aArguments[1] + "'";
		
	
	int i = 0;
	while (ifs.good())
	{
		string Line;
		std::getline( ifs,Line );
		if (Line.size() == 0)
			continue;
			
		std::vector<string> Arguments = ParseGTOperation(i++,Line);	
		CallBackGtWrite(Arguments);
		
	}
	ifs.close();
	#endif
}
//-----------------------------------------------------------------------------------

void CallBackGtRead(vector<string> aArguments )
{
     vector<BYTE > Data;
	 
    if (aArguments.size() != 2)
        throw string("Invalid argument count");
		
	if (gCurrentDevice->mActive)
		throw string("Can't read registers while device is running!");

    char RegType = aArguments[1][0];
    string Register = aArguments[1].erase(0,1);

    if (RegType != 'r' &&RegType != 'i')
        throw string("Invalid argument type, expected 'r' or 'i'");

    int RegId;
    sscanf(Register.c_str(), "%x", &RegId);
  //  cout << RegId << "\n";

    Data.push_back(UART_DEV_READ);
    Data.push_back(gCurrentDevice->mId);
    Data.push_back(0);
    Data.push_back((RegType == 'i') ? (RegId | 0x80): RegId);
	
	if (gVerbose)
	{
		for (int i = 0; i < Data.size(); i++)
			printf("-Debug- Data[%d] = %04x\n",i, Data[i]);
	}
	
	gDeviceManager->WriteUart( Data );
	
	if (RegType == 'i')
		PrintInstruction(gDeviceManager->ReadUartWord32());
	else	
		cout <<  gDeviceManager->ReadUartWord32() << "\n"; 
	

}
//-----------------------------------------------------------------------------------
void CallBackRGUDumpRegisters(vector<string> aArguments )
{
	for (int i = 0; i < RGU_MAX_REGS; i++)
	{
		printf("r%d\t",i);
		char RegId[8];
		sprintf(RegId,"r%d",i);
		vector<string> Args;
		Args.push_back("read");
		Args.push_back(RegId);
		CallBackGtRead(Args);
	}
}
//-----------------------------------------------------------------------------------
void CallBackGtDumpRegisters(vector<string> aArguments )
{
	for (int i = 0; i < GT_MAX_REGS; i++)
	{
		printf("r%d\t",i);
		char RegId[8];
		sprintf(RegId,"r%d",i);
		vector<string> Args;
		Args.push_back("read");
		Args.push_back(RegId);
		CallBackGtRead(Args);
	}
}

//-----------------------------------------------------------------------------------

void CallBackWriteControlRegister(vector<string> aArguments)
{
	vector<BYTE > Data;
	
	if (aArguments.size() != 2)
        throw string("Invalid argument count");

   

    int Value;
    sscanf(aArguments[1].c_str(), "%x", &Value);
	
    Data.push_back(UART_DEV_WRITE);
    Data.push_back(DEV_ID_CNTRL_REG);
    Data.push_back(0);
    Data.push_back(0);
	
	
	Data.push_back( (Value & 0xff000000) >> 24 );
    Data.push_back( (Value & 0x00ff0000) >> 16 );
    Data.push_back( (Value & 0x0000ff00) >> 8  );
    Data.push_back( Value & 0x000000ff );
	
	
	gDeviceManager->WriteUart( Data );
	
	cout <<  gDeviceManager->ReadUartWord32() << "\n"; 
}
//-----------------------------------------------------------------------------------
void CallBackResetAABBS(vector<string> aArguments)
{
	vector<string> Arguments;
	
	
	//Need to do read-modify-write
	//First Read
	vector<BYTE > Data;
	
    Data.push_back(UART_DEV_READ);
    Data.push_back(DEV_ID_CNTRL_REG);
    Data.push_back(0);
    Data.push_back(0);
	
	gDeviceManager->WriteUart( Data );
	string HexStringCurrentControlWord =  gDeviceManager->ReadUartWord32(); 
	 int CurrentControlWord;
    sscanf(HexStringCurrentControlWord.c_str(), "%x", &CurrentControlWord);
	
	int DeviceEnableBit = CurrentControlWord | (1 << CNTRL_DEV_RESET_AABBS);
	char Buffer[32];
	sprintf(Buffer,"0x%x",DeviceEnableBit);
	
	Arguments.push_back("");
	Arguments.push_back(string(Buffer));
	CallBackWriteControlRegister(Arguments);
	
	DeviceEnableBit = CurrentControlWord & ~(1 << CNTRL_DEV_RESET_AABBS);
	sprintf(Buffer,"0x%x",DeviceEnableBit);
	Arguments.clear();
	Arguments.push_back("");
	Arguments.push_back(string(Buffer));
	CallBackWriteControlRegister(Arguments);
	
	gCurrentDevice->mActive = false;
}
//-----------------------------------------------------------------------------------
void CallBackGtContinue(vector<string> aArguments)
{
	vector<string> Arguments;
	
	
	//Need to do read-modify-write
	//First Read
	vector<BYTE > Data;
	
    Data.push_back(UART_DEV_READ);
    Data.push_back(DEV_ID_CNTRL_REG);
    Data.push_back(0);
    Data.push_back(0);
	
	gDeviceManager->WriteUart( Data );
	string HexStringCurrentControlWord =  gDeviceManager->ReadUartWord32(); 
	 int CurrentControlWord;
    sscanf(HexStringCurrentControlWord.c_str(), "%x", &CurrentControlWord);
	
	int DeviceEnableBit = CurrentControlWord | (1 << (gCurrentDevice->mId - DEV_ID_AABB0));
	char Buffer[32];
	sprintf(Buffer,"0x%x",DeviceEnableBit);
	
	Arguments.push_back("c");
	Arguments.push_back(string(Buffer));
	CallBackWriteControlRegister(Arguments);
	gCurrentDevice->mActive = true;
}
//-----------------------------------------------------------------------------------
void CallBackGtStop(vector<string> aArguments)
{
	vector<string> Arguments;
	
	//Need to do read-modify-write
	//First Read
	vector<BYTE > Data;
	
    Data.push_back(UART_DEV_READ);
    Data.push_back(DEV_ID_CNTRL_REG);
    Data.push_back(0);
    Data.push_back(0);
	
	gDeviceManager->WriteUart( Data );
	string HexStringCurrentControlWord =  gDeviceManager->ReadUartWord32(); 
	 int CurrentControlWord;
    sscanf(HexStringCurrentControlWord.c_str(), "%x", &CurrentControlWord);
	
	int DeviceEnableBit = CurrentControlWord & ~(1 << (gCurrentDevice->mId - DEV_ID_AABB0));
	
	char Buffer[32];
	sprintf(Buffer,"0x%x",DeviceEnableBit);
	
	Arguments.push_back("c");
	Arguments.push_back(string(Buffer));
	CallBackWriteControlRegister(Arguments);
	gCurrentDevice->mActive = false;
}
//-----------------------------------------------------------------------------------
void CallBackStep(vector<string> aArguments)
{
	vector<string> Arguments;
	Arguments.push_back( "write" );
	
	char Value[256];
	sprintf(Value,"0%08x",0x80000000);
	Arguments.push_back( string(Value) );
	CallBackWriteControlRegister(Arguments);
	
	//We now need to clear the bit otherwise HW won't work properly
	
	Arguments.clear();
	Arguments.push_back( "write" );
	Arguments.push_back( "0x0" );
	CallBackWriteControlRegister(Arguments);
	
	//Now read the instruction that is about to execute
	vector<BYTE> Data;
	Data.push_back(UART_DEV_READ);
    Data.push_back(gCurrentDevice->mId);
    Data.push_back(0);
    Data.push_back( 0x80);
	
	gDeviceManager->WriteUart( Data );
	
	PrintInstruction(gDeviceManager->ReadUartWord32());
	
}
//-----------------------------------------------------------------------------------
void CallBackReadControlRegister(vector<string> aArguments)
{
	vector<BYTE > Data;
	
    Data.push_back(UART_DEV_READ);
    Data.push_back(DEV_ID_CNTRL_REG);
    Data.push_back(0);
    Data.push_back(0);
	
	gDeviceManager->WriteUart( Data );
	string HexString =  gDeviceManager->ReadUartWord32(); 
	
	 int Value;
    sscanf(HexString.c_str(), "%x", &Value);
	bitset<32> Bitset(Value);
	
	cout << HexString << "\n\n";
	/*
	for (int  i = 0; i < Bitset.size(); i++)
	{
		cout << "Bit[" << i << "]\t" << ((Bitset[i])? "ON":"OFF") << "\n";
	}
	*/
	
cout << "ENABLE_GT0\t"   <<       Bitset[0] << "\n";
cout << "ENABLE_GT1\t"   <<       Bitset[1] << "\n";
cout << "ENABLE_GT2\t"   <<       Bitset[2] << "\n";
cout << "ENABLE_GT3\t"   <<       Bitset[3] << "\n";
cout << "ENABLE_GT4\t"   <<       Bitset[4] << "\n";
cout << "ENABLE_GT5\t"   <<       Bitset[5] << "\n";
cout << "ENABLE_GT6\t"   <<       Bitset[6] << "\n";
cout << "ENABLE_GT7\t"   <<       Bitset[7] << "\n";
cout << "ENABLE_GT8\t"   <<       Bitset[8] << "\n";
cout << "RESET_ALL_GT\t" <<       Bitset[9] << "\n";
cout << "ENABLE_RGU\t"   <<       Bitset[10] << "\n";

	
}
//-----------------------------------------------------------------------------------
void CallBackReadCapabilitesRegister(vector<string> aArguments)
{
	vector<BYTE > Data;
	
	 if (aArguments.size() != 2)
        throw string("Invalid argument count");
		

    string Register = aArguments[1];
    int RegId;
    sscanf(Register.c_str(), "%x", &RegId);
	
    Data.push_back(UART_DEV_READ);
    Data.push_back(DEV_ID_CAPS_REG);
    Data.push_back(0);
    Data.push_back( RegId);
	
	
	gDeviceManager->WriteUart( Data );
	string HexString =  gDeviceManager->ReadUartWord32(); 
	
	 int Value;
    sscanf(HexString.c_str(), "%x", &Value);
	bitset<32> Bitset(Value);
	
	cout << HexString << "\n\n";
	

}
//-----------------------------------------------------------------------------------
void  CallBack_ListChildren(vector<string> aArguments )
{
    
    map<string, CDevice>::iterator I;

     for (I = gCurrentDevice->mChild.begin(); I != gCurrentDevice->mChild.end(); ++I)
        cout << I->first << "\n";


}
//-----------------------------------------------------------------------------------
void CallBackHelp(vector<string> aArguments )
{
	map<string,CCommand>::iterator I;

     for (I = gCurrentDevice->mCommands.begin(); I != gCurrentDevice->mCommands.end(); ++I)
        printf("%-10s\t\t%s\n",I->first.c_str(), I->second.mHelp.c_str() );
}
//-----------------------------------------------------------------------------------
void CallBackToggleVerboseMode(vector<string> aArguments )
{

	gVerbose = !gVerbose;
}
//-----------------------------------------------------------------------------------

CDeviceManager::CDeviceManager()
{

try
{
    map<string,CCommand>   Commands;
	//                                                     ValidWhenDeviceInative,  aSendToDevice
    Commands["cd"]          =  CCommand(CallBack_SetScopeToChild         ,   "Change scope"      );
    Commands["ls"]          =  CCommand(CallBack_ListChildren            ,   "List children under current scope"   );
	Commands["rcontrol"]    = CCommand(CallBackReadControlRegister       ,   "Read control register");
	Commands["rcap"]        = CCommand(CallBackReadCapabilitesRegister       ,   "Read capabilites register");
	Commands["help"]        = CCommand(CallBackHelp                      ,   "Shows help for current scope" );
	Commands["wcontrol"]    = CCommand(CallBackWriteControlRegister      ,   "Writes control register");
	Commands["verbosemode"] = CCommand(CallBackToggleVerboseMode         ,   "Toggles tool verbosity");
	Commands["loadscript"]  = CCommand(CallBackLoadScript                ,   "Loads a script");
	Commands["resetallgt"]  = CCommand(CallBackResetAABBS                ,   "Resets all of the GT units");
	
    mDevices["gpu"] = CDevice("gpu",0,NULL,Commands) ;

    
    Commands["read"]    = CCommand(CallBackGtRead , "reads a register" );
    Commands["write"]   = CCommand(CallBackGtWrite  , "writes a register" );
    Commands["iwrite"]  = CCommand(CalllBackiWrite  , "writes an instruction");
	Commands["d"]       = CCommand(CallBackGtDumpRegisters , "reads all registers"  );
	Commands["iload"]   = CCommand(CallBackLoadAABBProgramFile , "loads gt instructions from a file");
	Commands["s"]       = CCommand(CallBackStep , "single step execution");
	Commands["c"]       = CCommand(CallBackGtContinue , "continues execution");
	Commands["stop"]    = CCommand(CallBackGtStop , "stops execution");
	Commands["assert"]  = CCommand(CallBackAssert,  "asserts value in register");

    mDevices["gpu"].mChild["gt0"] = CDevice("gt0",DEV_ID_AABB0+0,&mDevices["gpu"],Commands) ;
    mDevices["gpu"].mChild["gt1"] = CDevice("gt1",DEV_ID_AABB0+1,&mDevices["gpu"],Commands) ;
	
	
	Commands["d"]       = CCommand(CallBackRGUDumpRegisters , "reads all registers"  );
	mDevices["gpu"].mChild["rgu"] = CDevice("rgu",DEV_ID_RGU,    &mDevices["gpu"],Commands) ;
	
	
    gCurrentDevice = &mDevices["gpu"];
    mUartFD = -1;
	gDeviceManager = this;
	
}

catch (string aError)
{
	cout << aError << "\n";
}
     
}//---------------------------------------------------------------------------
CDeviceManager::~CDeviceManager()
{
cout << "Closing UART communication\n";
	if (mUartFD > 0)
		close( mUartFD );
}
//---------------------------------------------------------------------------
bool   CDeviceManager::IsCurretDeviceActive( void )
{
	return gCurrentDevice->mActive;
}
//---------------------------------------------------------------------------
bool CDeviceManager::SendCommandToActiveDevice( vector<string> aTokens )
{
try
{
	if (aTokens.size() == 0)
		return true;
		
	if (aTokens[0] == "q")
		return false;
		
	string Command = aTokens[0];
	if (gCurrentDevice->mCommands.find(Command ) == gCurrentDevice->mCommands.end())
        throw string("Invalid command: '" + Command + "'\n");

    gCurrentDevice->mCommands[Command].mCallback(aTokens);

  
}

catch (string aMessage)
{
	cout << aMessage << "\n";
}
return true;
}
//---------------------------------------------------------------------------
void SetUartInterfaceAttributes (int aFd, int aSpeed, int aParity)
{
        struct termios tty;
        memset (&tty, 0, sizeof tty);
        if (tcgetattr (aFd, &tty) != 0)
             throw string("Error getting tty attrbiutes: ") + string(strerror(errno));
       
        cfsetospeed (&tty, aSpeed);
        cfsetispeed (&tty, aSpeed);

        tty.c_cflag = (tty.c_cflag & ~CSIZE) | CS8;     // 8-bit chars
        // disable IGNBRK for mismatched speed tests; otherwise receive break
        // as \000 chars
        tty.c_iflag &= ~IGNBRK;         // ignore break signal
        tty.c_lflag = 0;                // no signaling chars, no echo,
                                        // no canonical processing
        tty.c_oflag = 0;                // no remapping, no delays
        tty.c_cc[VMIN]  = 0;            // read doesn't block
        tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

        tty.c_iflag &= ~(IXON | IXOFF | IXANY); // shut off xon/xoff ctrl

        tty.c_cflag |= (CLOCAL | CREAD);// ignore modem controls,
                                        // enable reading
        tty.c_cflag &= ~(PARENB | PARODD);      // shut off parity
        tty.c_cflag |= aParity;
        tty.c_cflag &= ~CSTOPB;
        tty.c_cflag &= ~CRTSCTS;

        if (tcsetattr (aFd, TCSANOW, &tty) != 0)
            throw string("Error setting tty attrbiutes: ") + string(strerror(errno));
     
}
//---------------------------------------------------------------------------
void SetUartBlocking (int fd, int aBlocking)
{
        struct termios tty;
        memset (&tty, 0, sizeof tty);
        if (tcgetattr (fd, &tty) != 0)
			throw string("Error getting tty attrbiutes: ") + string(strerror(errno));

        tty.c_cc[VMIN]  = aBlocking ? 1 : 0;
        tty.c_cc[VTIME] = 5;            // 0.5 seconds read timeout

        if (tcsetattr (fd, TCSANOW, &tty) != 0)
            throw string("Error setting tty attrbiutes: ") + string(strerror(errno));
}
//---------------------------------------------------------------------------
void CDeviceManager::OpenUartPort( string aPortName )
{
	cout << "-I- Openning UART port '" << aPortName<< "' \n";
	mUartFD = open (aPortName.c_str(), O_RDWR | O_NOCTTY | O_SYNC);
	if (mUartFD < 0)
		throw  string("Error opening '") + aPortName + string("' ") + string(strerror(errno) );

	SetUartInterfaceAttributes(mUartFD, GPU_UART_SPEED, GPU_NO_PARITY );  
	SetUartBlocking (mUartFD, GPU_NO_BLOCKING);                

}
//---------------------------------------------------------------------------
void CDeviceManager::WriteUart( vector<BYTE > aMessage)
{

	BYTE * Bytes = new BYTE[aMessage.size()];
	for (int  i = 0; i < aMessage.size(); i++)
	{
		Bytes[i] = aMessage[i];
	//	printf("write: %02x\n",Bytes[i]);
	}
	
	write(mUartFD,Bytes,aMessage.size());
	usleep ((aMessage.size() + 25) * 100);
	delete[] Bytes;

	
}
//---------------------------------------------------------------------------
string CDeviceManager::ReadUartWord32(   )
{

	BYTE Buffer [4];
	read(mUartFD,Buffer,4);
	char Format[256];
	sprintf(Format,"0x%02x%02x%02x%02x",
		Buffer[0],Buffer[1],Buffer[2],Buffer[3]);

	sscanf(Format,"%x",&gLastReadValue);
	
	return string(Format);
	
}
//---------------------------------------------------------------------------
