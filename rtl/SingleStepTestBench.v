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

module SingleStepTestBench;

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
/*
   task WriteUartCommand
	(
		input[7:0]  DeviceId,
		input [7:0] RegisterIndex,
		input [31:0] Value,
		output oUartByteAvailable,
		output [7:0] oUartTx
	);
	begin
	
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		oUartTx = {`UART_WRITE,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		oUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		oUartTx = DeviceId;
		#(10*`GLOBAL_CLOCK_PERIOD)
		oUartByteAvailable = 0;		
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		oUartByteAvailable = 1;
		oUartTx = 8'd0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		
		oUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		oUartByteAvailable = 1;
		oUartTx = RegisterIndex;
		#(10*`GLOBAL_CLOCK_PERIOD)
		oUartByteAvailable = 0;	
		
	end
	endtask
	*/
	
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
		uut.AABB0.DATA_RAM.Ram[1]        = 32'd8;
		uut.AABB0.DATA_RAM.Ram[0]        = 32'd6;
		uut.AABB0.DATA_RAM.Ram[2]        = 32'd10;
		uut.AABB0.DATA_RAM.Ram[3]        = 32'd7;
	   uut.AABB0.INSTRUCTION_RAM.Ram[0] = {`CONTINUE, `NOBREAK, 2'b0,`AABB_SUB,`R0,`R1,`R2};		//8 - 6 = 2
		uut.AABB0.INSTRUCTION_RAM.Ram[1] = {`CONTINUE, `NOBREAK, 2'b0,`AABB_SUB,`R5,`R2,`R3};
		uut.AABB0.INSTRUCTION_RAM.Ram[2] = {`STOP, `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};
		uut.AABB0.INSTRUCTION_RAM.Ram[3] = {`STOP, `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};
			
		$display("Insn[0] = %x",uut.AABB0.INSTRUCTION_RAM.Ram[0]);
		$display("Insn[1] = %x",uut.AABB0.INSTRUCTION_RAM.Ram[1]);
		$display("Insn[2] = %x",uut.AABB0.INSTRUCTION_RAM.Ram[2]);
		$display("Insn[3] = %x",uut.AABB0.INSTRUCTION_RAM.Ram[3]);
	/*
		uut.AABB0.INSTRUCTION_RAM.Ram[3] = {`CONTINUE, `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};
		uut.AABB0.INSTRUCTION_RAM.Ram[4] = {`STOP,     `NOBREAK, 2'b0,`AABB_SUB,`R3,`R1,`R2};		//8 - 2 = 6
		uut.AABB0.INSTRUCTION_RAM.Ram[5] = {`STOP,     `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};*/
   
	//***************************************************//
	
		//Send the UART Command 1,
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_WRITE,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_CNTRL_REG;
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
		rUartTx = 8'd0;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
        
		//Now write the actual data to the memory  
		
		//Send the UART Command 2
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'b10000000;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd 0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		
		//******************************************//
		
		//Send the UART Command 2,
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_WRITE,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_CNTRL_REG;
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
		rUartTx = 8'd0;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
        
		//Now write the actual data to the memory  
		
		
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'b0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd 0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		
		//******************************************
		
		
		//Send the UART Command 1,
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_WRITE,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_CNTRL_REG;
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
		rUartTx = 8'd0;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
        
		//Now write the actual data to the memory  
		
		//Send the UART Command 2
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'b10000000;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd 0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = 8'd0;
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		//Request read from register R4 
		//Send the UART Command 1,
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_READ,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_AABB0;
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
		rUartTx = 8'd4;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		//Request read from register R1 
		//Send the UART Command 1,
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_READ,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_AABB0;
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
		rUartTx = 8'd1;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		#500
		
		//Request read from register R1 
		//Send the UART Command 1,
		#(5*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = {`UART_READ,7'b0};	
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;		
		
		//Send the Device Address 
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 1;
		rUartTx = `DEV_ID_AABB0;
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
		rUartTx = 8'd2;              //MEM Adrr LSW
		#(10*`GLOBAL_CLOCK_PERIOD)
		iUartByteAvailable = 0;	
		
		
	end
      
endmodule

