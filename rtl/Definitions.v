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


`ifndef DEFINITIONS_INCLUDED
`define DEFINITIONS_INCLUDED

/*******************************************************************************
Module Description:

	This module defines constants that are going to be used
	all over the code. By now you have may noticed that all
	constants are pre-compilation define directives. This is
	for simulation perfomance reasons mainly.
*******************************************************************************/

//******* SIMULATION SPECIFIC DEFINES *****************************************/
`timescale 1ns / 1ps					//The time scale used for simulation across all of the modules
`define GLOBAL_CLOCK_CYCLE  5		//The clock cycle used for testbench
`define GLOBAL_CLOCK_PERIOD 10	//The clock period used for testbenc


//Verilog provides a `default_nettype none compiler directive.  When
//this directive is set, implicit data types are disabled, which will make any
//undeclared signal name a syntax error. This is very usefull to avoid annoying
//automatic 1 bit long wire declaration where you don't want them to be!

`ifndef SYNTHESIS							//Unfortunaletly the XILINX uart module uses auto-wiring so need to disable this for synthesis
	`default_nettype none				//No auto-wiring
`endif

//******* STRUCTURE SPECIFIC DEFINES *****************************************/
//GLOBAL defines
`define GPU_WORD       32
`define GPU_LONGWORD   64
`define SCALE          17
`define GPU_AABB_COUNT 4


//UART defines
`define UART_WORD_OUT_SZ      8
`define UART_BAUD_RATE_CNT_SZ 5


//UART commands
`define UART_WRITE 1'b1
`define UART_READ  1'b0


//UART 32 bit bus defines
`define UART_RX_CMD_POS  31
`define UART_RX_DEV_ADDR_RNG 23:16
`define UART_RX_MEM_ADDR_RNG 15:0

//UART bus sizes
`define UART_MEM_ADDR_SZ 16
`define UART_DEV_ADDR_SZ  5
`define UART_DEV_MAX      32


//Device indetifiers
`define DEV_ID_NONE        0
`define DEV_ID_ECHO        1
`define DEV_ID_CNTRL_REG   2
`define DEV_ID_STATUS_REG  3
`define DEV_ID_AABB0       4
`define DEV_ID_AABB1       5
`define DEV_ID_AABB2       6
`define DEV_ID_AABB3       7
`define DEV_ID_AABB4       8
`define DEV_ID_AABB5       9
`define DEV_ID_AABB6       10
`define DEV_ID_AABB7       11
`define DEV_ID_RGU         12

`define CNTRL_DEV_EN_AABB0       0
`define CNTRL_DEV_EN_AABB1       1
`define CNTRL_DEV_EN_AABB2       2
`define CNTRL_DEV_EN_AABB3       3
`define CNTRL_DEV_EN_AABB4       4
`define CNTRL_DEV_EN_AABB5       5
`define CNTRL_DEV_EN_AABB6       6
`define CNTRL_DEV_EN_AABB7       7
`define CNTRL_DEV_EN_AABB8       8
`define CNTRL_DEV_RESET_AABBS    9
`define CNTRL_DEV_EN_RGU         10
`define CNTRL_STEP               31


////////////////////////////////////////////////////
//
//
//      AABB definitions
//
///////////////////////////////////////////////////
`define AABB_REG_BUS_SZ     3

`define AABB_OPERAND_B_RNG  2:0
`define AABB_OPERAND_A_RNG  5:3
`define AABB_DST_RNG        8:6
`define AABB_OPERATION_RNG  11:9
`define AABB_BREAKPOINT     14
`define AABB_STOP_BIT       15


`define AABB_NOP             3'd0
`define AABB_MUL             3'd1
`define AABB_SUB             3'd2
`define AABB_RET_IF_LT       3'd3
`define AABB_RET_IF_GT       3'd4
`define AABB_ADD             3'd5
`define AABB_POP             3'd6

/*
//Add two more bits to inst
`define AABB_FIFO_NO_READ    2'd0
`define AABB_FIFO_READ_KEEP  2'd1
`define AABB_FIFO_READ_POP   2'd2
`define RGU_FIFO_WRITE       2'd3

//Add one more bit to inst
`define AABB_CONTINUE        3'b000
`define AABB_BREAK           3'b001
`define AABB_STOP            3'b010
`define AABB_FIFO_READ_KEEP  3'b100
`define AABB_FIFO_READ_POP   3'b110
`define AABB_FIFO_READ_PUSH  3'b111


*/
`define CONTINUE 1'b0
`define STOP     1'b1

`define BREAK    1'b1
`define NOBREAK  1'b0

`define R0 3'd0
`define R1 3'd1
`define R2 3'd2
`define R3 3'd3
`define R4 3'd4
`define R5 3'd5
`define R6 3'd6
`define R7 3'd7

////////////////////////////////////////////////////
//
//
//      RGU definitions
//
////////////////////////////////////////////////////






`define RGU_UART_ADDR_INSN 7
`define RGU_RF_BUS_SZ      5
`define RGU_INSN_SZ        21

`define RGU_OPERAND_B_RNG  4:0
`define RGU_OPERAND_A_RNG  9:5
`define RGU_DST_RNG        14:10
`define RGU_OPERATION_RNG  17:15
`define RGU_PSTROB_BIT     18
`define RGU_BREAKPOINT     19
`define RGU_STOP_BIT       20


`define RGU_NOP             3'd0
`define RGU_MUL             3'd1
`define RGU_SUB             3'd2
`define RGU_ADD             3'd3
`define RGU_DIV             3'd4
`define RGU_SQRT            3'd5
`define RGU_PUSH            3'd6

`endif
