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

module StaticConfiguration
(
 
 input wire  [4:0]          			  iGpuCapabilitesAddr,
 output wire [`GPU_WORD-1:0]          oGpuCapabilitesData
 
 
 );

reg [4:0] rGpuCapabilitesData;

assign oGpuCapabilitesData = {27'b0,rGpuCapabilitesData};

always @( iGpuCapabilitesAddr )
begin
	case (iGpuCapabilitesAddr)
		5'b0: rGpuCapabilitesData  = 5'd`GPU_AABB_COUNT;
		5'b1: rGpuCapabilitesData  = 5'd`SCALE;
	default
		rGpuCapabilitesData = 5'hcaca;		
	endcase
end
endmodule
