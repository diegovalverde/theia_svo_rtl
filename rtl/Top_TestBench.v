`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   12:03:37 04/17/2014
// Design Name:   top
// Module Name:   C:/Users/diego/Google Drive/papilio/projects/uart_test/Top_TestBench.v
// Project Name:  uart_test
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module Top_TestBench;

	// Inputs
	reg iGlobalClock;
	reg iGlobalReset;
	reg rUartIn;
	reg wUartRx;
	
	
	always
	begin
		#5 iGlobalClock = ~iGlobalClock;
	end
	
	
	

	// Outputs
	wire oUartTx;

	// Instantiate the Unit Under Test (UUT)
	top uut (
		.iGlobalClock(iGlobalClock), 
		.iGlobalReset(iGlobalReset), 
		.oUartTx(wUartRx), 
		.iUartRx(rUartTx)
	);

	initial begin
		// Initialize Inputs
		iGlobalClock = 0;
		iGlobalReset = 0;
		iUartRx = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		iGlobalReset = 1'b1;
		#10
		iGlobalReset = 1'b0;
		
		
		//01001000 - H
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b1;
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b1;
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b0;

		//01100101 - e
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b1;
		#5 rUartTx = 1'b1;
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b1;
		#5 rUartTx = 1'b0;
		#5 rUartTx = 1'b1;

//01101100
//01101100
//01101111
//00100000
//01010111
//01101111
//01110010
//01101100
//01100100
	
	end
      
endmodule

