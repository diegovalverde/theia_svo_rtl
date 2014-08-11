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

module SimpleOperationTestBench;

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

reg rPush;
reg [31:0] rFifoData;

//assign uut.IN_FIFO0.iPush = rPush;
//assign uut.IN_FIFO0.iDataIn = rFifoData;

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
	/*	#(1*`GLOBAL_CLOCK_PERIOD)
		rPush = 1'b1;
		rFifoData = 32'hcaca;
		#(1*`GLOBAL_CLOCK_PERIOD);
		rPush = 0;*/
		
		uut.AABB0.INSTRUCTION_RAM.Ram[0] = {`CONTINUE, `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};
		uut.AABB0.INSTRUCTION_RAM.Ram[1] = {`CONTINUE, `NOBREAK, 2'b0,`AABB_POP,`R2,`R0,`R0};		//8 - 6 = 2
	   //uut.AABB0.INSTRUCTION_RAM.Ram[2] = {`CONTINUE, `NOBREAK, 2'b0,`AABB_SUB,`R2,`R1,`R0};		//8 - 6 = 2
		uut.AABB0.INSTRUCTION_RAM.Ram[3] = {`STOP, `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};
		uut.AABB0.INSTRUCTION_RAM.Ram[4] = {`STOP, `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};
		
		uut.RGU.DATA_RAM.Ram[1] = 32'h0xdeadbeef;
		uut.RGU.INSTRUCTION_RAM.Ram[0] = {`CONTINUE, `NOBREAK, 1'b0,`RGU_NOP,5'd0,5'd1,5'd2};
		uut.RGU.INSTRUCTION_RAM.Ram[1] = {`CONTINUE, `NOBREAK, 1'b0,`RGU_PUSH,5'd7,5'd1,5'd7};
			
		$display("%x",uut.AABB0.INSTRUCTION_RAM.Ram[0]);
		$display("%x",uut.AABB0.INSTRUCTION_RAM.Ram[1]);
		$display("%x",uut.AABB0.INSTRUCTION_RAM.Ram[2]);
	/*
		uut.AABB0.INSTRUCTION_RAM.Ram[3] = {`CONTINUE, `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};
		uut.AABB0.INSTRUCTION_RAM.Ram[4] = {`STOP,     `NOBREAK, 2'b0,`AABB_SUB,`R3,`R1,`R2};		//8 - 2 = 6
		uut.AABB0.INSTRUCTION_RAM.Ram[5] = {`STOP,     `NOBREAK, 2'b0,`AABB_NOP,`R0,`R0,`R0};*/
		uut.CNTRL_REG.FFD_CNTR.Q[`CNTRL_DEV_EN_AABB0] = 1'b1;
		uut.CNTRL_REG.FFD_CNTR.Q[`CNTRL_DEV_EN_RGU] = 1'b1;
	end
      
endmodule

