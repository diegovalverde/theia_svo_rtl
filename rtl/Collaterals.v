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

//--------------------------------------------------------------------------------------------------------------------------

module SELECT_1_TO_N # ( parameter SEL_WIDTH=4, parameter OUTPUT_WIDTH=16 )
 (
 input wire [SEL_WIDTH-1:0] Sel,
 input wire  En,
 output wire [OUTPUT_WIDTH-1:0] O
 );

reg[OUTPUT_WIDTH-1:0] shift;

always @ ( * )
begin
	if (~En)
		shift = 1;
	else
		shift = (1 << 	Sel);


end

assign O = ( ~En ) ? 0 : shift ;

//assign O = En & (1 << Sel);

endmodule 

//--------------------------------------------------------------------------------------------------------------------------
module CIRCULAR_SHIFTLEFT_POSEDGE # ( parameter SIZE=`GPU_WORD )
( input wire Clock, 
  input wire Reset,
  input wire[SIZE-1:0] Initial, 
  input wire      Enable,
  output wire[SIZE-1:0] O
);

reg [SIZE-1:0] tmp;


  always @(posedge Clock)
  begin
  if (Reset || tmp[SIZE-1])
		tmp <= Initial;
	else
	begin
		if (Enable)
			tmp <= tmp << 1;
	end	
  end
  
  
    assign O  = tmp;
endmodule
//--------------------------------------------------------------------------------------------------------------------------
module MUXFULLPARALELL_2SEL_GENERIC # ( parameter SIZE=`GPU_WORD )
 (
 input wire [1:0] Sel,
 input wire [SIZE-1:0]I1, I2, I3,I4,
 output reg [SIZE-1:0] O1
 );

always @( * )

  begin

    case (Sel)

      2'b00: O1 = I1;
      2'b01: O1 = I2;
		2'b10: O1 = I3;
		2'b11: O1 = I4;
		default: O1 = SIZE;

    endcase

  end

endmodule 
//--------------------------------------------------------------------------------------------------------------------------
module MUXFULLPARALELL_4SEL_GENERIC # ( parameter SIZE=`GPU_WORD )
 (
 input wire [3:0] Sel,
 input wire [SIZE-1:0] I0, I1, I2,I3,I4, I5, I6,I7,I8, I9, I10,I11,I12, I13, I14,I15,
 output reg [SIZE-1:0] O1
 );

always @( * )

  begin

    case (Sel)

      4'd0: O1 = I0;
      4'd1: O1 = I1;
		4'd2: O1 = I2;
		4'd3: O1 = I3;
		4'd4: O1 = I4;
      4'd5: O1 = I5;
		4'd6: O1 = I6;
		4'd7: O1 = I7;
		4'd8: O1 = I8;
      4'd9: O1 = I9;
		4'd10: O1 = I10;
		4'd11: O1 = I11;
		4'd12: O1 = I12;
      4'd13: O1 = I13;
		4'd14: O1 = I14;
		4'd15: O1 = I15;
		default: O1 = SIZE;

    endcase

  end

endmodule 

//--------------------------------------------------------------------------------------------------------------------------
module FFD_POSEDGE_SYNCRONOUS_RESET # ( parameter SIZE=`GPU_WORD )
(
	input wire				Clock,
	input wire				Reset,
	input wire				Enable,
	input wire [SIZE-1:0]	D,
	output reg [SIZE-1:0]	Q
);
	

always @ (posedge Clock) 
begin
	if ( Reset )
		Q <= {SIZE{1'b0}};
	else
	begin	
		if (Enable) 
			Q <= D; 
	end	
 
end//always

endmodule
//--------------------------------------------------------------------------------------------------------------------------
module RAM_SINGLE_READ_PORT # ( parameter DATA_WIDTH=1, parameter ADDR_WIDTH=32, parameter MEM_SIZE=400000 )
(
 input wire      Clock,
 input wire      iWriteEnable,
 input wire[ADDR_WIDTH-1:0] iReadAddress0,
 input wire[ADDR_WIDTH-1:0] iWriteAddress,
 input wire[DATA_WIDTH-1:0]    iDataIn,
 output reg [DATA_WIDTH-1:0]   oDataOut0
 
);

reg [DATA_WIDTH -1:0] Ram [MEM_SIZE-1:0];  

always @(posedge Clock) 
begin 
 
  if (iWriteEnable) 
   Ram[iWriteAddress] <= iDataIn; 
   
 
   oDataOut0 <= Ram[iReadAddress0]; 
   
  
end 
endmodule

//Dual port RAM.

//--------------------------------------------------------------------------------------------------------------------------
module RAM_DUAL_READ_PORT # ( parameter DATA_WIDTH=32, parameter ADDR_WIDTH=16, parameter MEM_SIZE=128 )
(
 input wire                    Clock,
 input wire                    iWriteEnable,
 input wire[ADDR_WIDTH-1:0]    iReadAddress0,
 input wire[ADDR_WIDTH-1:0]    iReadAddress1,
 input wire[ADDR_WIDTH-1:0]    iWriteAddress,
 input wire[DATA_WIDTH-1:0]    iDataIn,
 output reg [DATA_WIDTH-1:0]   oDataOut0,
 output reg [DATA_WIDTH-1:0]   oDataOut1
);

reg [DATA_WIDTH-1:0] Ram [MEM_SIZE-1:0];  

always @(posedge Clock) 
begin 
 
  /* verilator lint_off WIDTH */
  if (iWriteEnable) 
   Ram[iWriteAddress] <= iDataIn; 
   
 
   oDataOut0 <= Ram[iReadAddress0]; 
   oDataOut1 <= Ram[iReadAddress1]; 
    /* verilator lint_on WIDTH */
  
end 
endmodule

//------------------------------------------------
module SUB # (parameter SIZE=32)
(
input wire [SIZE-1:0] iA,iB,
output wire [SIZE-1:0] oR
);

	assign oR = iA - iB;
endmodule

//------------------------------------------------
module UPCOUNTER_POSEDGE # (parameter SIZE=32)
(
input wire Clock, Reset,
input wire [SIZE-1:0] Initial,
input wire Enable,
output reg [SIZE-1:0] Q
);


  always @(posedge Clock )
  begin
      if (Reset)
        Q <= Initial;
      else
		begin
		if (Enable)
			Q <= Q + 1;
			
		end			
  end

endmodule
//------------------------------------------------


module SynchFIFO #( parameter DATA_WIDTH=32, parameter ADDR_WIDTH=4, parameter MEM_SIZE=16 )
(
	input  wire                   iClock,
	input  wire                   iReset,
	input  wire                   iPush,
	input  wire [DATA_WIDTH-1:0]  iDataIn,
	input  wire                   iPop,
	output wire  [DATA_WIDTH-1:0] oDataOut,
	output wire                   oFull,
	output wire                   oEmpty
	
);
	reg [ADDR_WIDTH-1:0]  rWritePointer;
	wire [ADDR_WIDTH-1:0] wReadPointer;
	//reg rReadPointer;
	reg [DATA_WIDTH -1:0] Ram [MEM_SIZE-1:0];  
	
	assign oFull    = (rWritePointer == (MEM_SIZE-1))? 1'b1:1'b0;
	assign oDataOut =  Ram[wReadPointer];
	assign oEmpty   = (rWritePointer == 0)?1'b1:1'b0;
	
	assign wReadPointer = rWritePointer - 1'b1;
	
	always @( posedge iClock)
	begin
		if (iReset)
		begin
			rWritePointer <= 0;
		end
		else
		
		if (iPush)
		begin	
			Ram[rWritePointer] <= iDataIn;
		//	rReadPointer  <= rWritePointer;
			rWritePointer <= rWritePointer + 1'b1;
		end
 
		else if (iPop)
		begin
			
			rWritePointer <= rWritePointer - 1'b1;
	//		rReadPointer  <= rWritePointer;
		end	
			
		//oDataOut <= Ram[wReadPointer]; 
		
		begin
		end
	end




endmodule
//------------------------------------------------