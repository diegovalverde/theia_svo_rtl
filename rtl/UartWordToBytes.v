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


`define UARTSS_LISTEN 0
`define UARTSS_BYTE0  1
`define UARTSS_WAIT0  2
`define UARTSS_BYTE1  3
`define UARTSS_WAIT1  4
`define UARTSS_BYTE2  5
`define UARTSS_WAIT2  6
`define UARTSS_BYTE3  7
`define UARTSS_WAIT3  8

module UartUnpacker
(
 input wire                           iClock, 
 input wire                           iReset,
 input wire                           iWordAvailable,
 input wire  [`GPU_WORD-1:0]          iWord,
 output wire [`UART_WORD_OUT_SZ-1:0]  oUartTx8,
 output reg                           oByteTransmit
);

reg [1:0]     rWordSelect;


MUXFULLPARALELL_2SEL_GENERIC # ( `UART_WORD_OUT_SZ ) MUX_BYTE
 (
 .Sel( rWordSelect   ),
 .I4(  iWord[7:0]    ),
 .I3(  iWord[15:8]   ),
 .I2(  iWord[23:16]  ),
 .I1(  iWord[31:24]  ),
 .O1(  oUartTx8      )
 );



//--------------------------------------------------------
// Current State Logic //
reg [7:0]    rCurrentState,rNextState;

always @(posedge iClock )
begin
     if( iReset!=1 )
        rCurrentState <= rNextState;
   else
		  rCurrentState <= `UARTSS_LISTEN;  
end
//--------------------------------------------------------

always @( * )
 begin
  
  case (rCurrentState)
  //----------------------------------------
  `UARTSS_LISTEN:
  begin
		rWordSelect    = 2'd0;
		oByteTransmit  = 1'b0;
		
		if (iWordAvailable)
			rNextState = `UARTSS_BYTE0;
		else
			rNextState = `UARTSS_LISTEN;
  end
  //----------------------------------------
  `UARTSS_BYTE0:
  begin
		rWordSelect    = 2'd0;
		oByteTransmit  = 1'b1;
		
		rNextState = `UARTSS_WAIT0;
		
  end
  //----------------------------------------
  `UARTSS_WAIT0:
  begin
		rWordSelect    = 2'd0;
		oByteTransmit  = 1'b0;
		
		rNextState = `UARTSS_BYTE1;
  end
  //----------------------------------------
  `UARTSS_BYTE1:
  begin
		rWordSelect    = 2'd1;
		oByteTransmit  = 1'b1;
		
		rNextState = `UARTSS_WAIT1;
		
  end
  //----------------------------------------
  `UARTSS_WAIT1:
  begin
		rWordSelect    = 2'd1;
		oByteTransmit  = 1'b0;
		
		rNextState = `UARTSS_BYTE2;
  end
  //----------------------------------------
  `UARTSS_BYTE2:
  begin
		rWordSelect    = 2'd2;
		oByteTransmit  = 1'b1;
		
		rNextState = `UARTSS_WAIT2;
		
  end
  //----------------------------------------
  `UARTSS_WAIT2:
  begin
		rWordSelect    = 2'd2;
		oByteTransmit  = 1'b0;
		
		rNextState = `UARTSS_BYTE3;
  end
  //----------------------------------------
  `UARTSS_BYTE3:
  begin
		rWordSelect    = 2'd3;
		oByteTransmit  = 1'b1;
		
		rNextState = `UARTSS_WAIT3;
		
  end
  //----------------------------------------
  `UARTSS_WAIT3:
  begin
		rWordSelect    = 2'd3;
		oByteTransmit  = 1'b0;
		
		rNextState = `UARTSS_LISTEN;
  end
  //----------------------------------------
  default:
  begin
		rWordSelect = 2'b0;
		oByteTransmit  = 1'b0;
		
		rNextState = `UARTSS_LISTEN;
  end
  //----------------------------------------
	endcase
end

	
endmodule
