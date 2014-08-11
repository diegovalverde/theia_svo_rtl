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
module THEIA
(
 input wire                          iGlobalClock, 
 input wire                          iGlobalReset,
 input wire                          iUartClock,
 input wire                          iUartByteAvailable,
 output wire                         oUartTxByteAvailable,
 output wire [`UART_WORD_OUT_SZ-1:0] oUartTx,
 input wire  [`UART_WORD_OUT_SZ-1:0] iUartRx
);

wire                        wUartWord32Available;
wire                        wUartTxStrobe;                                       //GPU wants to transmit out to CPU
wire                        wAABBStep;                                           //Single step signal strobe from Control Register unit
wire [`GPU_WORD-1:0]        wUartDataRxWord,wUartWriteData32,wUartDataTxWord;
wire [`GPU_WORD-1:0]        wUartDataTx_AABB0,wUartDataTx_AABB1,wUartDataTx_RGU,wUartDataTx_StaticConf;
wire                        wUartWrite;                                           //Can be either UART_READ or UART_WRITE
wire                        wUartCmdStrobe,wUartCmdStrobe_Latched;                //Indicates that a UART command is ready to be processed by on or more devices
wire[`UART_MEM_ADDR_SZ-1:0] wUartMemoryAddress;				                         //Address were UART wants to read and write in given device memory
wire[`UART_DEV_ADDR_SZ-1:0] wUartDeviceAddress;				                         //Device address identifier were UART wants to read/write
wire[`UART_DEV_ADDR_SZ-1:0] wUartDeviceAddress_Latched;                           //Device address identifier were UART wants to read/write
wire[`UART_DEV_MAX-1:0]     wUartDeviceSelector;                                  //Bitmap contianing 1 bit for each UART addresable device
wire [1:0]                  wAABBInFifoPush,wAABBInFifoPop;
wire [1:0]                  wAABBInFifoFull,wAABBInFifoEmpty ;
wire [`GPU_WORD-1:0]	       wAABBInFifoWriteData[1:0] ,wAABBInFifoReadData[1:0];
wire [`GPU_WORD-1:0]        wControlRegister;
wire [`GPU_WORD-1:0]        wRGUPushData;
wire                        wRGUPushStrobe;


FFD_POSEDGE_SYNCRONOUS_RESET #(`UART_DEV_ADDR_SZ) FFD_UART_SEL	//Make sure to hold the value of wUartDeviceAddress 
(
	.Clock(   iGlobalClock       ),
	.Reset(   iGlobalReset       ),
	.Enable(  wUartCmdStrobe     ),
	.D(       wUartDeviceAddress ),
	.Q(       wUartDeviceAddress_Latched )
);


FFD_POSEDGE_SYNCRONOUS_RESET #(1) FFD_UART_UART_TX_STB	//Make sure to hold the value of wUartDeviceAddress 
(
	.Clock(   iGlobalClock       ),
	.Reset(   iGlobalReset       ),
	.Enable(  1'b1              ),
	.D(       wUartCmdStrobe    ),
	.Q(       wUartCmdStrobe_Latched      )
);

assign wUartTxStrobe = wUartCmdStrobe_Latched;

MUXFULLPARALELL_4SEL_GENERIC # ( `GPU_WORD ) UADRT_MUX
 (
 .Sel(wUartDeviceAddress_Latched),
 .I0(32'b0            ),		//None
 .I1(wUartDataRxWord  ),		//Echo
 .I2(wControlRegister ),		//Control register
 .I3(32'b0),						//Status register
 .I4(wUartDataTx_AABB0),		//AABB0
 .I5(wUartDataTx_AABB1),		//AABB1
 .I6(32'b0),						//AABB2
 .I7(32'b0),						//AABB3
 .I8(32'b0),						//AABB4
 .I9(32'b0),						//AABB5
 .I10(32'b0),						//AABB6
 .I11(32'b0),						//AABB7
 .I12(wUartDataTx_RGU),       //RGU			
 .I13(wUartDataTx_StaticConf), 						//Static Configuration
 .I14(32'b0),
 .I15(32'b0),
 .O1( wUartDataTxWord )
 );
 
StaticConfiguration GPU_CAPS
(
.iGpuCapabilitesAddr( wUartMemoryAddress[4:0] ),
.oGpuCapabilitesData( wUartDataTx_StaticConf  )
);

//This block transforms the 8bit message chunks comming from the UART into GPU_WORD 
//32 bit words.
UartPacker DS8To32
( 
 .iClock(             iUartClock           ), 
 .iReset(             iGlobalReset         ),
 .iUartByteAvailable( iUartByteAvailable   ),
 .iUartRx(            iUartRx              ),
 .oUartRx32(          wUartDataRxWord      ),
 .oWordAvailable(     wUartWord32Available )
);


UartUnpacker SS32To8
(
	.iClock(             iUartClock           ), 
	.iReset(             iGlobalReset         ),
	.iWordAvailable(     wUartTxStrobe        ),
	.iWord(              wUartDataTxWord      ),
	.oByteTransmit(      oUartTxByteAvailable ),
	.oUartTx8(           oUartTx              )
	
);


UartTxCommandControl UARTCNTRL
(
  .iClock(               iUartClock           ), 
  .iReset(               iGlobalReset         ),
  .iUartWord32Available( wUartWord32Available ),
  .iUartDataRxWord(      wUartDataRxWord      ),
  .oUartCommand(         wUartWrite           ),
  .oUartDeviceAddress(   wUartDeviceAddress   ),
  .oUartMemoryAddress(   wUartMemoryAddress   ),
  .oMemWriteData(        wUartWriteData32     ),
  .oIssueCommand(        wUartCmdStrobe       )
  
);

//This blocks maps the wUartDeviceAddress into a single bit in wUartDeviceSelector corresponding
//to the device where the UART command shall arrive
SELECT_1_TO_N # ( .SEL_WIDTH(`UART_DEV_ADDR_SZ), .OUTPUT_WIDTH(`UART_DEV_MAX) ) UART_DEV_SEL
 (
 .Sel( wUartDeviceAddress   ),
 .En(  wUartCmdStrobe       ),
 .O(   wUartDeviceSelector  )
 );


ControlRegisterUnit CNTRL_REG
(
 .iClock(           iGlobalClock                                         ),
 .iReset(           iGlobalReset                                         ),
 .iWriteEnable(     wUartWrite & wUartDeviceSelector[`DEV_ID_CNTRL_REG ] ),
 .iValue(           wUartWriteData32                                     ),
 .oControlRegister( wControlRegister                                     ),
 .oStepAABB(        wAABBStep                                            )    
 
 );
 
 
RayGenerationUnit RGU
(
 .iClock(        iGlobalClock                                              ),
 .iReset(        iGlobalReset                                              ),
 .iEnable(       wControlRegister[`CNTRL_DEV_EN_RGU ]                      ),
 .oFifoPush(     wRGUPushStrobe                                            ),
 .oFifoData(     wRGUPushData                                              ),
 .iUartSelected( wUartDeviceSelector[`DEV_ID_RGU ]                         ),
 .iUartWrite(    wUartWrite                                                ),
 .iUartAddr(     wUartMemoryAddress[7:0]                                   ),
 .iUartData(     wUartWriteData32                                          ),
 .oUartData(     wUartDataTx_RGU                                           )
);

assign wAABBInFifoWriteData[0] = wRGUPushData;
assign wAABBInFifoPush[0] = wRGUPushStrobe;

SynchFIFO IN_FIFO0
(
   .iClock(       iGlobalClock                                                ),
   .iReset(       iGlobalReset  | wControlRegister[`CNTRL_DEV_RESET_AABBS ]   ),
	.iPush(        wAABBInFifoPush[0]                                          ),
	.iDataIn(      wAABBInFifoWriteData[0]                                     ),
	.iPop(         wAABBInFifoPop[0]                                           ),
	.oDataOut(     wAABBInFifoReadData[0]                                      ),
	.oFull(        wAABBInFifoFull[0]                                          ),
	.oEmpty(       wAABBInFifoEmpty[0]                                         )
);

AABBIntersect AABB0
(
 .iClock(              iGlobalClock                                              ),
 .iReset(              iGlobalReset  | wControlRegister[`CNTRL_DEV_RESET_AABBS ] ),
 .iEnable(             wControlRegister[`CNTRL_DEV_EN_AABB0 ]  | wAABBStep       ),
 .iUartSelected(       wUartDeviceSelector[`DEV_ID_AABB0 ]                       ),
 .iUartWrite(          wUartWrite                                                ),
 .iUartAddr(           wUartMemoryAddress[7:0]                                   ),
 .iUartData(           wUartWriteData32                                          ),
 .oUartData(           wUartDataTx_AABB0                                         ),
 .iInputFifoEmpty(     wAABBInFifoEmpty[0]      ),
 .iInputFifoFull(      wAABBInFifoFull[0]       ),
 .oInputFifoPop(       wAABBInFifoPop[0]        ),
 .iInputFifoReadData(  wAABBInFifoReadData[0]   )
 
);


AABBIntersect AABB1
(
 .iClock(        iGlobalClock                                              ),
 .iReset(        iGlobalReset  | wControlRegister[`CNTRL_DEV_RESET_AABBS ] ),
 .iEnable(       wControlRegister[`CNTRL_DEV_EN_AABB1 ]                    ),
 .iUartSelected( wUartDeviceSelector[`DEV_ID_AABB1 ]                       ),
 .iUartWrite(    wUartWrite                                                ),
 .iUartAddr(     wUartMemoryAddress[7:0]                                   ),
 .iUartData(     wUartWriteData32                                          ),
 .oUartData(     wUartDataTx_AABB1                                         )
);

endmodule
