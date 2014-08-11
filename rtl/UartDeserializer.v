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

`define UARTDS_LISTEN           0
`define UARTDA_LATCH_NEXT_BYTE  1
`define UARTDS_WAIT_NEXT_BYTE       2

///////////////////////////////////////////////////////////
//
//
// Description: Transform 8bit UART input into 32 bit ouputs
//
//
///////////////////////////////////////////////////////////


module UartPacker
(
 input wire                           iClock, 
 input wire                           iReset,
 input wire                           iUartByteAvailable,
 input wire  [`UART_WORD_OUT_SZ-1:0]  iUartRx,
 output wire [`GPU_WORD-1:0]          oUartRx32,
 output wire                          oWordAvailable
);


wire [4:0] wByteSelect;
reg        rLatchNextByte;


assign oWordAvailable = wByteSelect[4];


//--------------------------------------------------------
// Current State Logic //
reg [7:0]    rCurrentState,rNextState;
always @(posedge iClock )
begin
     if( iReset!=1 )
        rCurrentState <= rNextState;
   else
		  rCurrentState <= `UARTDS_LISTEN;  
end
//--------------------------------------------------------

always @( * )
 begin
  
  case (rCurrentState)
  //----------------------------------------
  //Wait for reset sequence to complete,
  //Or until we are enabled
  `UARTDS_LISTEN:
  begin
		rLatchNextByte = 1'b0;
  
      if (iUartByteAvailable )
		  rNextState = `UARTDA_LATCH_NEXT_BYTE;
		else  
		  rNextState = `UARTDS_LISTEN;
  end
  //----------------------------------------
  `UARTDA_LATCH_NEXT_BYTE:
  begin
		rLatchNextByte = 1'b1;
		
		rNextState = `UARTDS_WAIT_NEXT_BYTE;
  end
  //----------------------------------------
 `UARTDS_WAIT_NEXT_BYTE:
  begin
		rLatchNextByte = 1'b0;
		
		if (iUartByteAvailable )
			rNextState = `UARTDS_WAIT_NEXT_BYTE;
		else
			rNextState = `UARTDS_LISTEN;
  end
  //----------------------------------------
  default:
  begin
		rLatchNextByte = 1'b0;
		 
		rNextState = `UARTDS_LISTEN;
  end
  //----------------------------------------
  endcase
end




CIRCULAR_SHIFTLEFT_POSEDGE # (5) BYTE_COUNT
(
.Clock(   iClock              ), 
.Reset(   iReset              ),
.Initial( 5'b1                ),
.Enable(  rLatchNextByte      ),
.O(       wByteSelect         )
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `UART_WORD_OUT_SZ ) FFD_W0
(
.Clock(   iClock              ), 
.Reset(   iReset              ),
.Enable(  wByteSelect[3]  & rLatchNextByte    ),
.D(       iUartRx             ),
.Q(       oUartRx32[7:0]      )
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `UART_WORD_OUT_SZ ) FFD_W1
(
.Clock(   iClock              ), 
.Reset(   iReset              ),
.Enable(  wByteSelect[2]   & rLatchNextByte    ),
.D(       iUartRx             ),
.Q(       oUartRx32[15:8]     )
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `UART_WORD_OUT_SZ ) FFD_W2
(
.Clock(   iClock              ), 
.Reset(   iReset              ),
.Enable(  wByteSelect[1]    & rLatchNextByte   ),
.D(       iUartRx             ),
.Q(       oUartRx32[23:16]    )
);

FFD_POSEDGE_SYNCRONOUS_RESET # ( `UART_WORD_OUT_SZ ) FFD_W3
(
.Clock(   iClock              ), 
.Reset(   iReset              ),
.Enable(  wByteSelect[0]   & rLatchNextByte    ),
.D(       iUartRx             ),
.Q(       oUartRx32[31:24]    )
);




endmodule
