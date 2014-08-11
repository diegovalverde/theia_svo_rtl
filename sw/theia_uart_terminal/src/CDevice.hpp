#ifndef CDEVICE_H
#define CDEVICE_H

using namespace std;
#include <vector>
#include <string>
#include <map>
#include <iostream>

typedef unsigned char BYTE ;
class CCommand
{
public:
	CCommand(){}
	
	CCommand(void  (*aCallback)( vector<string> aArguments ),  string aHelp = "")
	{
		mCallback = aCallback;
		mHelp = aHelp;
	};
    
    void  (*mCallback)( vector<string> aArguments );
    bool   mSendToDevice;
	
	string mHelp;
 };

class CDevice
{
public:
    

public:
    CDevice() {mActive   = false;};
    CDevice(string aName,int aId,CDevice * aParent, map<string,CCommand> aCommands )
    {
        mId       = aId;
        mName     = aName;
        mParent   = aParent;
        mCommands = aCommands;
		mActive   = false;
    }

public:
    void ReadDeviceEnableFromDut();
    bool IsActive();


public:
    bool            mActive;            //UART Commands cannot be issued while device is active
    int             mId;
    string          mName;
    CDevice         * mParent;

    map<string,CCommand>       mCommands;
    map<string,CDevice>        mChild;
};

#endif // CDEVICE_H
