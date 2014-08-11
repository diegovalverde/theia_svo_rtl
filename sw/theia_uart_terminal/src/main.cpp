#include "CDeviceManager.hpp"
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>
#include <readline/readline.h>
#include <readline/history.h>
#include <sstream>
#include <iterator>

int main( int argc, char *argv[] )
{
	
 string ShellPrompt,PortName,ScriptPath;
 char* Input;
 CDeviceManager DeviceManager;
 
 
 if ( argc < 2 ) 
  {
     cout<<"usage: "<< argv[0] <<" -t </dev/ttyUSBXXX>\n [-l script_file ";
     return 0;
  }


 char Option;
while ((Option = getopt(argc,argv,"t:l:")) != -1)
{
  switch ( Option)
  {
    case 't': PortName = optarg; break;
    case 'l': ScriptPath = optarg; break;
  }
}

if (PortName.empty())
{
    cout << "tty port name not specified\n";
    exit(1);
}
 
 		
std::cout << "---------------------------------------------------------------\n";
std::cout << "  \n";
std::cout << " _/_/_/_/_/  _/                  _/            \n";
std::cout << "   _/      _/_/_/      _/_/          _/_/_/   \n";
std::cout << "  _/      _/    _/  _/_/_/_/  _/  _/    _/    \n";
std::cout << " _/      _/    _/  _/        _/  _/    _/     \n";
std::cout << "_/      _/    _/    _/_/_/  _/    _/_/_/      \n";
std::cout << "\n";
std::cout << "\n";
std::cout << "---------------------------------------------------------------\n";
 try
 {
    DeviceManager.OpenUartPort( PortName );
    if (! ScriptPath.empty())
    {
         cout << "Loading script '" << ScriptPath << "'\n";
         DeviceManager.LoadScript( ScriptPath );
    }
 
 
    // Configure readline to auto-complete paths when the tab key is hit.
    rl_bind_key('\t', rl_complete);
 
    while (1)
    {
        
        ShellPrompt = string("\n") + DeviceManager.GetCurrentDeviceName() + "::" + ((DeviceManager.IsCurretDeviceActive())?"<RUNNING>":"");
 
        // Display prompt and read input (n.b. input must be freed after use)...
        Input = readline(ShellPrompt.c_str());
 
	string Line(Input);
	if (Line.length())
	  add_history(Line.c_str());
		
	stringstream ss(Line);
	std::istream_iterator<string> begin(ss);
	std::istream_iterator<string> end;
	vector<string> Tokens(begin, end);
		
		
	if (!DeviceManager.SendCommandToActiveDevice(Tokens))
	  break;
        
        free(Input);
    }
	return 0;
	
}

catch (string aError )
{
	cout << aError << "\n";
}
}

