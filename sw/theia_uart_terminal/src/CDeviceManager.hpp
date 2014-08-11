#ifndef CDEVICE_MANAGER_H
#define CDEVICE_MANAGER_H

#include "CDevice.hpp"

#define GPU_UART_SPEED 3000000
#define GPU_NO_PARITY  0
#define GPU_NO_BLOCKING 0

#define DEV_ID_CNTRL_REG 2
#define DEV_ID_CAPS_REG  13
#define DEV_ID_AABB0 4
#define DEV_ID_RGU 12
#define UART_DEV_WRITE 0x80
#define UART_DEV_READ 0x00

class CDeviceManager
{
	public:
		CDeviceManager();
		~CDeviceManager();
		
	public:	
		string GetCurrentDeviceName( void );
		bool   IsCurretDeviceActive( void );
		bool   SendCommandToActiveDevice( vector<string> aCommand);
		void   LoadScript(string aPath );
		void   WriteUart( vector<BYTE>  aMessage);
		string ReadUartWord32( void );
		void   OpenUartPort( string aPortName );
		
	public:
		int             	mUartFD;
		map<string,CDevice> mDevices;
};
#endif
