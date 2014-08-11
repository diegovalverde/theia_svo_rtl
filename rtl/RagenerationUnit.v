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


module RayGenerationUnit
(
 input wire                       iClock,
 input wire                       iReset,
 input wire                       iEnable,
  
 //FIFO Signals
 output reg                    oFifoPush,
 output wire [`GPU_WORD-1:0]   oFifoData,
 
 //UART signals
 input wire                    iUartSelected,
 input wire                    iUartWrite,
 input wire   [7:0]            iUartAddr,
 input wire   [`GPU_WORD-1:0]  iUartData,
 output wire  [`GPU_WORD-1:0]  oUartData
);

wire [`RGU_INSN_SZ-1:0]          wInstructionData,wCurrentInstruction;
wire [2:0]                       wOperation;
wire [4:0]                       wInstructionAddr,wInstructionPointer;
wire                             wInstructionWriteEnable;
wire [`RGU_RF_BUS_SZ-1:0]        wRegReadAddr0,wRegReadAddr1,wRegWriteAddr,wDestination;
wire                             wRegWriteEnable;
reg  [`GPU_WORD-1:0]  rResult;
wire [`GPU_WORD-1:0]  wRegWriteData, wSrtRoot;
wire [`GPU_WORD-1:0]  wA, wB, wSubResult;
reg                   rDataWriteEnable;
wire                  wInstructionStopBit;


assign oFifoData   = wA;


assign oUartData               = (iUartAddr[`RGU_UART_ADDR_INSN]) ? wCurrentInstruction   : wB ;	//Select between instruction or register to output into UART
assign wInstructionAddr        = (iEnable) ? wInstructionPointer     : iUartAddr[4:0];
assign wInstructionData        = iUartData[15:0];
assign wInstructionWriteEnable = (~iEnable & iUartAddr[`RGU_UART_ADDR_INSN] & iUartWrite & iUartSelected );
assign wInstructionStopBit     = wCurrentInstruction[ `RGU_STOP_BIT ];

//Register file UART MUX select
assign wRegReadAddr0    = (iEnable) ? wCurrentInstruction[ `RGU_OPERAND_B_RNG ] : iUartAddr[`RGU_RF_BUS_SZ-1:0];
assign wRegReadAddr1    = wCurrentInstruction[ `RGU_OPERAND_A_RNG ];
assign wRegWriteAddr    = (iEnable) ?  wDestination : iUartAddr[`RGU_RF_BUS_SZ-1:0];
assign wRegWriteEnable  = (iEnable) ? rDataWriteEnable           : (~iUartAddr[`RGU_UART_ADDR_INSN] & iUartWrite & iUartSelected);
assign wRegWriteData    = (iEnable) ? rResult                    : iUartData;





UPCOUNTER_POSEDGE # (5) IP
(
.Clock(   iClock                            ), 
.Reset(   iReset                            ),
.Initial( 5'b0                              ),
.Enable(  iEnable & ~wInstructionStopBit    ),
.Q(       wInstructionPointer               )
);

RAM_DUAL_READ_PORT # ( .DATA_WIDTH(32), .ADDR_WIDTH(`RGU_RF_BUS_SZ), .MEM_SIZE(32) ) DATA_RAM
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


RAM_SINGLE_READ_PORT # ( .DATA_WIDTH(`RGU_INSN_SZ), .ADDR_WIDTH(5), .MEM_SIZE(32) ) INSTRUCTION_RAM
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
.D(       wCurrentInstruction [ `RGU_OPERATION_RNG ]  ),
.Q(       wOperation                                   )
);

/*
FFD_POSEDGE_SYNCRONOUS_RESET # (1) FFD_PSTROB
(
.Clock(   iClock                                       ), 
.Reset(   iReset                                       ),
.Enable(  1'b1                                         ),
.D(       wCurrentInstruction [ `RGU_PSTROB_BIT ]      ),
.Q(       wOPStrob                                     )
);
*/
FFD_POSEDGE_SYNCRONOUS_RESET # (`RGU_RF_BUS_SZ) FFD_DST
(
.Clock(   iClock                                       ), 
.Reset(   iReset                                       ),
.Enable(  1'b1                                         ),
.D(       wCurrentInstruction[ `RGU_DST_RNG ]         ),
.Q(       wDestination                                 )
);




SUB SUBTRACT
(
	.iA( wA),
	.iB( wB ),
	.oR( wSubResult )
);


SQUAREROOT_LUT SQRT
(
	.I(wA),
	.O(wSrtRoot)
);	
always @ ( * )
begin
	case (wOperation)
	
	
	`RGU_NOP:
	begin
		rDataWriteEnable   = 1'b0;
		rResult            = 32'b0;
		oFifoPush          = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns RGU NOP",$time );
		`endif
	end
	
	`RGU_MUL: 
	begin
		rDataWriteEnable   = 1'b1;
		rResult            = wA * wB;
		oFifoPush          = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns RGU  r[%d] = r[%d] * r[%d] =  %x",$time, wRegWriteAddr, wRegReadAddr1, wRegReadAddr0, rResult );
		`endif
	end
	
	`RGU_SUB: 
	begin
		rDataWriteEnable   = 1'b1;
      rResult            = wSubResult;
		oFifoPush          = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns RGU r[%d] = r[%d] - r[%d] =  %x - %x = %x",$time, wRegWriteAddr,wRegReadAddr1, wRegReadAddr0, wA, wB, rResult );
		`endif
	end
	
	`RGU_DIV: 
	begin
		rDataWriteEnable   = 1'b1;
      rResult            = wA / wB;
		oFifoPush          = 1'b0;
		
		`ifndef SYNTHESIS
			$display("%dns RGU  r[%d] = r[%d] - r[%d] =  %x - %x = %x",$time, wRegWriteAddr,wRegReadAddr1, wRegReadAddr0, wA, wB, rResult );
		`endif
	end
	
	`RGU_SQRT:
	begin
	   rDataWriteEnable   = 1'b1;
		rResult            = wSrtRoot;
		oFifoPush          = 1'b0;
	end
	
	`RGU_PUSH:
	begin
	   rDataWriteEnable   = 1'b1;
		rResult            = wSrtRoot;
		oFifoPush          = 1'b1;
		`ifndef SYNTHESIS
			$display("%dns RGU  PUSH %x",$time,  wA );
		`endif
		
	end
	
	default:
	begin
		rDataWriteEnable   = 1'b0;
		rResult            = 32'b0;
		oFifoPush          = 1'b0;
	end
	endcase
end
/*
	 
	 
	 
	 float normalized_i = ((float)i / W) - 0.5;
	  float normalized_j = ((float)j / H) - 0.5;


	  CVector Temp_i((normalized_i * Camera.Right.X), (normalized_i * Camera.Right.Y),(normalized_i * Camera.Right.Z));
	  CVector Temp_j((normalized_j * Camera.Up.X), (normalized_j * Camera.Up.Y),(normalized_j * Camera.Up.Z));

	  CVector image_point = (Temp_i + Temp_j);
	 // image_point = image_point + CameraPostion;// + (CameraPostion + CVector(FocalDistance*camera_direction.X,FocalDistance*camera_direction.Y,FocalDistance*camera_direction.Z));
	  image_point.XTraslation( Camera.Position.X );
	  image_point.YTraslation( Camera.Position.Y );
	  image_point.ZTraslation( Camera.Position.Z );

	  Point = image_point + 
		  CVector(
		  Camera.FocalDistance*Camera.Direction.X,
		  Camera.FocalDistance*Camera.Direction.Y,
		  Camera.FocalDistance*Camera.Direction.Z);
		  
		   Point     = GetPlanePoint(i,j,W,H,Camera);
	  CVector Direction = Point - Camera.Position;
	  
	  SUB dirX PointX CameraPosX
	  SUB dirY PointY CameraPosY
	  SUB dirZ PointZ CameraPosZ
	  
	  MUL dirX2 dirX dirX
	  MUL dirY2 dirY dirY
	  MUL dirZ2 dirZ dirZ
	  
	  ADD Lenght dirX2 dirY2
	  nop
	  ADD Lenght Lenght dirZ2
	  
	  sqrt( Lenght )
	  
	  push BottonLeftX
	  push TopRightX
	  push Lenght / dirX2
	  
	  push BottonLeftX
	  push TopRightX
	  push Lenght / dirX2
	  
	  push BottonLeftZ
	  push TopRightZ
	  push Lenght / dirZ2
	  
	  
	  
*/
/*
//----------------------------------------------------------
function GenerateRay()
{
	vector UnnormalizedDirection, S,Xn, tmp;
	gDebugState = DB_STATE_GEN_RAY;
	UnnormalizedDirection = (ProjectionWindowMin + Pixel2DPosition * ProjectionWindowScale  ) - CameraPosition;	
	
	tmp = UnnormalizedDirection * UnnormalizedDirection;		//tmp = (x^2,y^2,z^2)   
	S = tmp.xxx + tmp.yyy + tmp.zzz;
	Xn = inv_sqrt ( S ); // this is 1/sqrt( int( S )) = Xn
	RayDirection = UnnormalizedDirection * ( (Xn >> R0.yyy)*((0x60000,0x60000,0x60000)  - S*Xn*Xn ) );
	
	
			  RayDirection.x = 0xffff1ea7;
			  RayDirection.y = 0xfffe3d54;
			  RayDirection.z = 0xffffa525;
	
		 
		
	return ;

}
*/


endmodule
