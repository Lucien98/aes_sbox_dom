// 
// Copyright (C) 2025 Gehui Yang
// 
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// 

`timescale  1ns / 1ps
module tb_lin_map();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam MATRIX_SEL = 1;

    // General signals
	reg clk = 1;
	//reg rst;

    reg [7:0] DataInxDI;
    wire [7:0] DataOutxDO;

    lin_map #(.MATRIX_SEL(MATRIX_SEL)) inst_lin_map (
        .DataInxDI(DataInxDI),
        .DataOutxDO(DataOutxDO)
    );

    // Create clock
	always@(*) #Td clk<=~clk;
    
    initial begin
        //assign DataInxDI = 8'b10101010;
        for (integer i = 0; i < 256; i = i + 1) begin
                DataInxDI = i;
                #Td;
        end
        #Td;
    end


endmodule
