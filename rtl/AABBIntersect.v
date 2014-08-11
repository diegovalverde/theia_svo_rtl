
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


`define AABB_UART_ADDR_INSN 7



module AABBIntersect
(
 input wire        iClock,
 input wire        iReset,
 input wire        iEnable,
 
 //input wire[31:0] iInputBuffer,
 output reg          oIntersectionFound,
 //UART signals
 input wire                    iUartSelected,
 input wire                    iUartWrite,
 input wire   [7:0]            iUartAddr,
 input wire   [`GPU_WORD-1:0]  iUartData,
 output wire  [`GPU_WORD-1:0]  oUartData,
 //Input FIFO signals
 input wire                    iInputFifoEmpty,
 input wire                    iInputFifoFull,
 output reg                    oInputFifoPop,
 input wire [`GPU_WORD-1:0]    iInputFifoReadData
 
);

wire [15:0]  wInstructionData,wCurrentInstruction;
wire [2:0]   wOperation;
wire [4:0]   wInstructionAddr,wInstructionPointer;
wire         wInstructionWriteEnable;

wire [2:0]   wRegReadAddr0,wRegReadAddr1,wRegWriteAddr,wDestination;
wire         wRegWriteEnable;

reg  [`GPU_WORD-1:0]  rResult;
wire [`GPU_WORD-1:0]  wRegWriteData;
reg                   rSubInvert;
wire [`GPU_WORD-1:0]  wA, wB,wSub_A, wSub_B, wSubResult;
reg          rDataWriteEnable;
wire         wResultSign;
wire         wInstructionStopBit;

assign oUartData               = (iUartAddr[`AABB_UART_ADDR_INSN]) ? wCurrentInstruction   : wB ;	//Select between instruction or register to output into UART
assign wInstructionAddr        = (iEnable) ? wInstructionPointer     : iUartAddr[4:0];
assign wInstructionData        = iUartData[15:0];
assign wInstructionWriteEnable = (~iEnable & iUartAddr[`AABB_UART_ADDR_INSN] & iUartWrite & iUartSelected );
assign wInstructionStopBit     = wCurrentInstruction[ `AABB_STOP_BIT ];

//Register file UART MUX select
assign wRegReadAddr0    = (iEnable) ? wCurrentInstruction[ `AABB_OPERAND_B_RNG ] : iUartAddr[2:0];
assign wRegReadAddr1    = wCurrentInstruction[ `AABB_OPERAND_A_RNG ];
assign wRegWriteAddr    = (iEnable) ?  wDestination : iUartAddr[2:0];
assign wRegWriteEnable  = (iEnable) ? rDataWriteEnable           : (~iUartAddr[`AABB_UART_ADDR_INSN] & iUartWrite & iUartSelected);
assign wRegWriteData    = (iEnable) ? rResult                    : iUartData;

UPCOUNTER_POSEDGE # (5) IP
(
.Clock(   iClock                            ), 
.Reset(   iReset                            ),
.Initial( 5'b0                              ),
.Enable(  iEnable & ~wInstructionStopBit    ),
.Q(       wInstructionPointer               )
);

RAM_DUAL_READ_PORT # ( .DATA_WIDTH(32), .ADDR_WIDTH(`AABB_REG_BUS_SZ), .MEM_SIZE(8) ) DATA_RAM
(
  .Clock(          iClock           ) ,
  .iWriteEnable(   wRegWriteEnable  ),
  .iReadAddress0(  wRegReadAddr0    ),
  .iReadAddress1(  wRegReadAddr1    ),
  .iWriteAddress(  wRegWriteAddr    ),
  .iDataIn(        wRegWriteData    ),
  .oDataOut0(      wB               ),
  .oDataOut1(      wA               )
 
);


RAM_SINGLE_READ_PORT # ( .DATA_WIDTH(16), .ADDR_WIDTH(5), .MEM_SIZE(32) ) INSTRUCTION_RAM
(
  .Clock( iClock ) ,
  .iWriteEnable(  wInstructionWriteEnable ),
  .iReadAddress0( wInstructionPointer     ),
  .iWriteAddress( wInstructionAddr        ),
  .iDataIn(       wInstructionData        ),
  .oDataOut0(     wCurrentInstruction     )
 
);


FFD_POSEDGE_SYNCRONOUS_RESET # (3) FFD_OP
(
.Clock(   iClock                                       ), 
.Reset(   iReset                                       ),
.Enable(  1'b1                                         ),
.D(       wCurrentInstruction [ `AABB_OPERATION_RNG ]  ),
.Q(       wOperation                                   )
);


FFD_POSEDGE_SYNCRONOUS_RESET # (3) FFD_DST
(
.Clock(   iClock                                       ), 
.Reset(   iReset                                       ),
.Enable(  1'b1                                         ),
.D(       wCurrentInstruction[ `AABB_DST_RNG ]         ),
.Q(       wDestination                                 )
);



assign wSub_A      = (rSubInvert)? wB : wA; 
assign wSub_B      = (rSubInvert)? wA : wB; 
assign wResultSign =  wSubResult[31];

SUB SUBTRACT
(
	.iA( wSub_A),
	.iB( wSub_B ),
	.oR( wSubResult )
);

always @ ( * )
begin
	case (wOperation)
	
	
	`AABB_NOP:
	begin
		rDataWriteEnable   = 1'b0;
		oIntersectionFound = 1'b0;
		rSubInvert         = 1'b0;
		rResult            = `GPU_WORD'b0;
		oInputFifoPop      = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns NOP",$time );
		`endif
	end
	
	`AABB_MUL: 
	begin
		rDataWriteEnable    = 1'b1;
		oIntersectionFound  = 1'b0;
		rSubInvert          = 1'b0;
		rResult             = wA * wB;
		oInputFifoPop       = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns r[%d] = r[%d] * r[%d] =  %x",$time, wRegWriteAddr, wRegReadAddr1, wRegReadAddr0, rResult );
		`endif
	end
	
	`AABB_SUB: 
	begin
		rDataWriteEnable   = 1'b1;
		oIntersectionFound = 1'b0;
		rSubInvert         = 1'b0;
		rResult            = wSubResult;
		oInputFifoPop       = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns r[%d] = r[%d] - r[%d] =  %x - %x = %x",$time, wRegWriteAddr,wRegReadAddr1, wRegReadAddr0, wA, wB, rResult );
		`endif
	end
	
	`AABB_RET_IF_LT: 
	begin
		rDataWriteEnable   = 1'b0;
		oIntersectionFound = ~wResultSign;
		rSubInvert         = 1'b1;
		rResult            = wSubResult;
		oInputFifoPop      = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns if ( r[%d] < r[%d] ) then return %d ",$time,  wRegReadAddr1, wRegReadAddr0, oIntersectionFound );
		`endif
	end
	
	`AABB_RET_IF_GT: 
	begin
		rDataWriteEnable   = 1'b0;
		oIntersectionFound = wResultSign;
		rSubInvert         = 1'b1;
		rResult            = wSubResult;
		oInputFifoPop       = 1'b0;
		
		
		`ifndef SYNTHESIS
			$display("%dns if ( r[%d] > r[%d] ) then return %d ",$time,  wRegReadAddr1, wRegReadAddr0, oIntersectionFound );
		`endif
		
	end
	
	
	`AABB_POP: 
	begin
		rDataWriteEnable    = 1'b1;
		oIntersectionFound  = 1'b0;
		rSubInvert          = 1'b0;
		rResult             = iInputFifoReadData;
		oInputFifoPop       = 1'b1;
		
		
		
		`ifndef SYNTHESIS
			$display("%dns pop ",$time);
		`endif
		
	end
	
	
	default:
	begin
		rDataWriteEnable   = 1'b0;
		oIntersectionFound = 1'b0;
		rSubInvert         = 1'b0;
		rResult            = 32'b0;
		oInputFifoPop      = 1'b0;
	end
	endcase
end
/*
	//FIFO = {aBottomLeft.X,TopRight.X,aRay.mInvDirection.X}
	
	SUB txmin aBottomLeft.X aRay.mOrigen.X
	pop
	SUB txmax TopRight.X    aRay.mOrigen.X
	pop
	MUL txmin tmin  aRay.mInvDirection.X
	MUL txmax txmax aRay.mInvDirection.X
	
	pop
	//FIFO = {aBottomLeft.Y,TopRight.Y,aRay.mInvDirection.Y}
	if (tmin > tmax) 
		swap(tmin, tmax);
	
	SUB tymin aBottomLeft.Y  aRay.mOrigen.Y
	SUB tymax TopRight.Y  aRay.mOrigen.Y
	
	MUL tymin tymin aRay.mInvDirection.Y
	MUL tymax tymax aRay.mInvDirection.Y
	
	 if (tymin > tymax) 
		swap(tymin, tymax);
		
	 if ((tmin > tymax) )
        return false;
		  
	 if (tymin > tmax)
			return false;
		  
    if (tymin > tmin)
        tmin = tymin;
		  
    if (tymax < tmax)
        tmax = tymax;	
		  
	 pop
    //FIFO = {aBottomLeft.Z,TopRight.Z,aRay.mInvDirection.Z}
	 
	 SUB tzmin aBottomLeft.Z  aRay.mOrigen.Z	
	 pop
	 SUB tzmax TopRight.Z  aRay.mOrigen.Z
	 pop
	 MUL tzmin tymin aRay.mInvDirection.Z
	 MUL tzmax tymax aRay.mInvDirection.Z
	 pop
	 
	 if (tzmin > tzmax) 
		swap(tzmin, tzmax);

    if ((tmin > tzmax) || (tzmin > tmax))
        return false;

    return true;
	 
*/
/*
	 float tmin = (aBottomLeft.X - aRay.mOrigen.X) * aRay.mInvDirection.X;
    float tmax = (TopRight.X - aRay.mOrigen.X) * aRay.mInvDirection.X;
    if (tmin > tmax) swap(tmin, tmax);
    float tymin = (aBottomLeft.Y - aRay.mOrigen.Y) * aRay.mInvDirection.Y;
    float tymax = (TopRight.Y - aRay.mOrigen.Y) * aRay.mInvDirection.Y;
    if (tymin > tymax) swap(tymin, tymax);
    if ((tmin > tymax) || (tymin > tmax))
        return false;
    if (tymin > tmin)
        tmin = tymin;
    if (tymax < tmax)
        tmax = tymax;
    float tzmin = (aBottomLeft.Z - aRay.mOrigen.Z) * aRay.mInvDirection.Z;
    float tzmax = (TopRight.Z - aRay.mOrigen.Z) * aRay.mInvDirection.Z;
    if (tzmin > tzmax) 
		swap(tzmin, tzmax);

    if ((tmin > tzmax) || (tzmin > tmax))
        return false;

    return true;
*/

endmodule
