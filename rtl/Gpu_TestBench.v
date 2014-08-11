/**********************************************************************************
Theia, Ray Cast Programable graphic Processing Unit.
Copyright (C) 2014  Diego Valverde (diego.valverde.g@gmail.com)

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

***********************************************************************************/


`include "Definitions.v"

module Gpu_TestBench;

	// Inputs
	reg iGlobalClock;
	reg iGlobalReset;
	reg iUartByteAvailable;
	reg [7:0] iUartRx,rUartTx;

	// Outputs
	wire oUartTxByteAvailable;
	wire [7:0] wUartRx;
	
	always
	begin
		#`GLOBAL_CLOCK_CYCLE iGlobalClock = ~iGlobalClock;
	end

	// Instantiate the Unit Under Test (UUT)
	THEIA uut (
		.iGlobalClock(iGlobalClock), 
		.iUartClock(iGlobalClock),
		.iGlobalReset(iGlobalReset), 
		.iUartByteAvailable(iUartByteAvailable), 
		.oUartTxByteAvailable(oUartTxByteAvailable), 
		.oUartTx(wUartRx), 
		.iUartRx(rUartTx)
	);

	initial begin
		// Initialize Inputs
		iGlobalClock = 0;
		iGlobalReset = 0;
		iUartByteAvailable = 0;
		iUartRx = 0;
		rUartTx = 0;
		// Wait 100 ns for global reset to finish
		#100;
		iGlobalReset = 1;
		#(50*`GLOBAL_CLOCK_PERIOD)
		iGlobalReset = 0;
		
		//Send the UART Command 1, this is command that will write the word 'HOLA' in ABB[1].R[7]
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_WRITE,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_AABB1;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Mem address
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'b0;					//MEM Adrr MSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd7;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
        
		//Now write the actual data to the memory  
		
		//Send the UART Command 2
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd72;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd 79;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Mem address
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd76;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd65;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		
		////////////////////////////////////////
		//
		// Write ADIOS
		//
		///////////////////////////////////////
		
		//Send the UART Command 1, this is command that will write the word 'ADIOS' in ABB[1].R[6]
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_WRITE,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_AABB1;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Mem address
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'b0;					//MEM Adrr MSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd6;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
        
		//Now write the actual data to the memory  
		
		//Send the UART Command 2
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd65;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd 68;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Mem address
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd73;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd79;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		////////////////////////////////////////
		//
		//Now, read the value back into the CPU
		//
		////////////////////////////////////////
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_READ,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_AABB1;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Mem address
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'b0;					//MEM Adrr MSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd7;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		//////////////////////////////////////////////////////
		//
		//
		//		ECHO TEST
		//
		//
		//////////////////////////////////////////////////////
	`ifdef NAHH	  
		//Send the UART Command 2
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd72;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd 79;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Mem address
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd76;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd65;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
	
		
		
		
		
		
		
		
		
		
		
		
		//Send the UART Command 3
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd66;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd 65;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Mem address
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd66;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd69;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
`endif	
	end
      
endmodule

