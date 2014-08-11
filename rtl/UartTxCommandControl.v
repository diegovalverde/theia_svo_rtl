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
`define UARTCNTR_STANBY           0
`define UARTCNTR_DELAY            1
`define UARTCNTR_LATCH_WRITE_DATA 2
`define UARTCNTR_ISSUE_CMD        3

module UartTxCommandControl
(
 input wire                           iClock, 
 input wire                           iReset,
 input wire                           iUartWord32Available,
 input wire [`GPU_WORD-1:0]           iUartDataRxWord,
 output wire                          oUartCommand,
 output wire [`UART_DEV_ADDR_SZ-1:0]  oUartDeviceAddress,
 output wire[`UART_MEM_ADDR_SZ-1:0]   oUartMemoryAddress,
 output wire [`GPU_WORD-1:0]          oMemWriteData,
 output wire                          oIssueCommand
);

reg rLatchWriteData, rLatchCommand, rIssueCommand;
wire [`UART_DEV_ADDR_SZ-1:0]  wUartDeviceAddress;

assign oUartDeviceAddress = (rIssueCommand) ? wUartDeviceAddress : `UART_DEV_ADDR_SZ'b0;
assign oIssueCommand      = rIssueCommand; 


FFD_POSEDGE_SYNCRONOUS_RESET # ( 1 ) FFD_CMD
(
.Clock(   iClock                                 ), 
.Reset(   iReset                                 ),
.Enable(  rLatchCommand                          ),
.D(       iUartDataRxWord[`UART_RX_CMD_POS]      ),
.Q(       oUartCommand                           )
);


FFD_POSEDGE_SYNCRONOUS_RESET # ( `UART_DEV_ADDR_SZ ) FFD_DEV_ADDR
(
.Clock(   iClock                                 ), 
.Reset(   iReset                                 ),
.Enable(  rLatchCommand                          ),
.D(       iUartDataRxWord[`UART_RX_DEV_ADDR_RNG] ),
.Q(       wUartDeviceAddress                     )
);


FFD_POSEDGE_SYNCRONOUS_RESET # ( `UART_MEM_ADDR_SZ ) FFD_MEM_ADDR
(
.Clock(   iClock                                 ), 
.Reset(   iReset                                 ),
.Enable(  rLatchCommand                          ),
.D(       iUartDataRxWord[`UART_RX_MEM_ADDR_RNG] ),
.Q(       oUartMemoryAddress                     )
);


FFD_POSEDGE_SYNCRONOUS_RESET # ( `GPU_WORD ) FFD_WD
(
.Clock(   iClock              ), 
.Reset(   iReset              ),
.Enable(  rLatchWriteData     ),
.D(       iUartDataRxWord     ),
.Q(       oMemWriteData       )
);


//--------------------------------------------------------
// Current State Logic //
reg [7:0]    rCurrentState,rNextState;
always @(posedge iClock )
begin
     if( iReset!=1 )
        rCurrentState <= rNextState;
   else
		  rCurrentState <= `UARTCNTR_STANBY;  
end
//--------------------------------------------------------

always @( * )
 begin
  
  case (rCurrentState)
  //----------------------------------------
  `UARTCNTR_STANBY:
  begin
		rLatchWriteData = 1'b0;
		rLatchCommand   = iUartWord32Available;
		rIssueCommand   = 1'b0;
  
      if (iUartWord32Available &  iUartDataRxWord[`UART_RX_CMD_POS] == `UART_WRITE)
		  rNextState = `UARTCNTR_DELAY;
		else if ( iUartWord32Available & iUartDataRxWord[`UART_RX_CMD_POS] == `UART_READ )  
		  rNextState = `UARTCNTR_ISSUE_CMD;
		else  
		  rNextState = `UARTCNTR_STANBY;
  end
  //----------------------------------------
  `UARTCNTR_DELAY:
  begin
       rLatchWriteData = 1'b0;
		 rLatchWriteData = 1'b0;
		 rIssueCommand   = 1'b0;
		 
		 if (iUartWord32Available == 1'b0)
			rNextState = `UARTCNTR_LATCH_WRITE_DATA;
		 else
		   rNextState = `UARTCNTR_DELAY;
   end	 
  //----------------------------------------
  `UARTCNTR_LATCH_WRITE_DATA:
  begin
     rLatchWriteData = iUartWord32Available; 
	  rLatchCommand   = 1'b0;
	  rIssueCommand   = 1'b0;	  
	  
	  if (iUartWord32Available)
			rNextState = `UARTCNTR_ISSUE_CMD;
	  else
			rNextState = `UARTCNTR_LATCH_WRITE_DATA;
  end
  //----------------------------------------
  `UARTCNTR_ISSUE_CMD:
  begin
		  rLatchWriteData = 1'b0;
		  rLatchCommand   = 1'b0;
		  rIssueCommand   = 1'b1;
		  
		  rNextState = `UARTCNTR_STANBY;
  end
  //----------------------------------------
  default:
  begin
        rLatchWriteData = 1'b0;
		  rLatchCommand   = 1'b0;
		  rIssueCommand   = 1'b0;
		  
		  rNextState = `UARTCNTR_STANBY;
  end
  //----------------------------------------
  endcase
 end 


endmodule
