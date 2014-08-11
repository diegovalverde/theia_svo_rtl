
`define SYNTHESIS 1 
`include "Definitions.v"

//`define ECHO_TEST 1

module top
(
input wire  iGlobalClock, 
input wire  iGlobalReset,
output wire oUartTx,
input wire  iUartRx

);


//====== XILINX UART MODULES ================//
reg [`UART_BAUD_RATE_CNT_SZ:0]      rBaudCount;
reg                                 rEn_16_X_Baud;
wire [`UART_WORD_OUT_SZ-1:0]      	wUartDataRx,wUartDataTx;                        // UART 1 Byte internal signals
wire            							wUartRxDataAvailable, wUartTxDataAvailable;		// UART serial input/ouput signals
wire                                wUartClock;													// 96Mhz clock used for UART


//This block transforms the 8bit message chunks comming from the UART into GPU_WORD 
//32 bit words.

`ifdef ECHO_TEST
wire [31:0] wUartDataRxWord;
wire wUartWord32Available;

UartPacker DS8To32
( 
 .iClock(             wUartClock              ), 
 .iReset(             iGlobalReset            ),
 .iUartByteAvailable( wUartRxDataAvailable    ),
 .iUartRx(            wUartDataRx             ),
 .oUartRx32(          wUartDataRxWord      ),
 .oWordAvailable(     wUartWord32Available )
);


UartUnpacker SS32To8
(
	.iClock(             wUartClock           ), 
	.iReset(             iGlobalReset         ),
	.iWordAvailable(     wUartWord32Available ),
	.iWord(              wUartDataRxWord      ),
	.oUartTx8(           wUartDataTx          ),
	.oByteTransmit(      wUartTxDataAvailable )
	
);
`else
	//assign wUartDataTx          = wUartDataRx;
	//assign wUartTxDataAvailable = wUartRxDataAvailable;
	
		THEIA GPU 
		(
		.iGlobalClock(         wUartClock                   ), 
		.iUartClock(           wUartClock                   ),
		.iGlobalReset(         iGlobalReset                 ), 
		.iUartByteAvailable(   wUartRxDataAvailable         ), 
		.oUartTxByteAvailable( wUartTxDataAvailable         ), 
		.oUartTx(              wUartDataTx                  ), 
		.iUartRx(              wUartDataRx                  )
	);
`endif




////////////////////////////////////////////////////////////////////////////
//                                                                        //
//                           **  UART **                                  //
//                                                                        //
////////////////////////////////////////////////////////////////////////////


//Instantiate Digital Clock Manager
dcm32to96 UART_CLOCK_DCM
(
	.CLK_IN1(  iGlobalClock ),
	.CLK_OUT1( wUartClock   )
); 


//--------------------------------------------------
always @ (posedge wUartClock )
begin
	if (rBaudCount == 1)
	begin
		rBaudCount    = 1'b0;
		rEn_16_X_Baud = 1'b1;
	end
	else
	begin
		rBaudCount    = rBaudCount + 1'b1;
		rEn_16_X_Baud = 1'b0;	
	end
		
end
//--------------------------------------------------

uart_rx6 UART_RX 
(
.serial_in(           iUartRx              ),
.en_16_x_baud(        rEn_16_X_Baud        ),
.data_out(            wUartDataRx          ), //8 bits
.buffer_read(         1'b1                 ),
.buffer_data_present( wUartRxDataAvailable ), //8 bits from UART became available for reading
.buffer_reset(        1'b0                 ),
.clk(                 wUartClock           ) 
);


uart_tx6 UART_TX
(
.data_in(             wUartDataTx          ),	//Amaze yourself! put any 8b'char in here and see the magic
.buffer_write(        wUartTxDataAvailable ),
.buffer_reset(        1'b0                 ),
.clk(                 wUartClock           ),
.en_16_x_baud(        rEn_16_X_Baud        ),
.serial_out(          oUartTx              )
 );

endmodule
