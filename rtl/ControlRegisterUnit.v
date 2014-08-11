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

`define STEP_LISTEN 0
`define STEP_SET    1
`define STEP_UNSET  2

//To save Hardware a Mask+Value was not implemented, instead the software need to perform 
//a read-modify-write operation in order to preseve the original values

module ControlRegisterUnit
(
 input wire                           iClock, 
 input wire                           iReset,
 input wire                           iWriteEnable,
 input wire  [`GPU_WORD-1:0]          iValue,
 output wire [`GPU_WORD-1:0]          oControlRegister,
 output reg                           oStepAABB
 
 );

reg rStep;

//--------------------------------------------------------
// Current State Logic //
reg [2:0]    rCurrentState,rNextState;

always @(posedge iClock )
begin
     if( iReset!=1 )
        rCurrentState <= rNextState;
   else
		  rCurrentState <= `STEP_LISTEN;  
end
//--------------------------------------------------------

always @( * )
 begin
  
  case (rCurrentState)
  //----------------------------------------
  `STEP_LISTEN:
  begin
		oStepAABB    = 1'd0;
		
		if ( iValue[`CNTRL_STEP] )
			rNextState = `STEP_SET;
		else
			rNextState = `STEP_LISTEN;
  end
  //----------------------------------------
  `STEP_SET:
  begin
		oStepAABB = 1'b1;
		
		rNextState = `STEP_UNSET;
  end
  //----------------------------------------
  `STEP_UNSET:
  begin
		oStepAABB = 1'b0;
		
		if (iValue[`CNTRL_STEP])
			rNextState = `STEP_UNSET;
		else	
			rNextState = `STEP_LISTEN;
  end
  //----------------------------------------
  default:
  begin
		oStepAABB = 1'b0;
	
		rNextState = `STEP_LISTEN;
	end
  //----------------------------------------
  endcase
end
  
  

FFD_POSEDGE_SYNCRONOUS_RESET # ( `GPU_WORD ) FFD_CNTR
(
.Clock(   iClock                                    ), 
.Reset(   iReset                                    ),
.Enable(  iWriteEnable & ~iValue[`CNTRL_STEP]       ),
.D(       iValue                                    ),
.Q(       oControlRegister                          )
);

endmodule
