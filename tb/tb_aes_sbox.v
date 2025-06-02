// 
// Copyright (C) 2025 Feng Zhou, Gehui Yang
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

`timescale 1ns/1ps
module tb_aes_sbox ();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam N = 2;
    localparam PIPELINED = 1;
    localparam EIGHT_STAGED = 0;
    localparam SHARES = 4; // change it to test different cases

    // General signals
	reg ClkxCI;
	// reg RstxBI;
    `include "blind.vh"
    localparam blind_n_rnd = _blind_nrnd(SHARES);
    reg [coeff*SHARES*(SHARES-1)-1 : 0] RandomZ;
    localparam bcoeff = _bcoeff(SHARES);

    reg [bcoeff*blind_n_rnd-1:0] RandomB;
    wire [8*SHARES-1 : 0] _XxDI;
    wire [8*SHARES-1 : 0] _QxDO;

    reg [7:0] XxDI [SHARES-1 : 0];
    wire [7:0] QxDO [SHARES-1 : 0];

    reg [7:0] X;
    reg [7:0] Q;

    for (genvar i = 0; i < SHARES; i=i+1) begin
        for (genvar j = 0; j < 8; j=j+1) begin
            assign _XxDI[i*8+j] = XxDI[i][j];
            assign QxDO[i][j] = _QxDO[i*8+j];
        end
    end

    aes_sbox #(.PIPELINED(PIPELINED), .EIGHT_STAGED(EIGHT_STAGED), .SHARES(SHARES))
    inst_aes_sbox (
        .ClkxCI(ClkxCI),
        // .RstxBI(RstxBI),
        ._XxDI(_XxDI),
        .RandomZ(RandomZ),
        .RandomB(RandomB),
        ._QxDO(_QxDO)
    );

    // Create clock
	always@(*) #Td ClkxCI<=~ClkxCI;

	initial begin
        ClkxCI = 1;
		// RstxBI = 0;
        #T;
        // RstxBI = 1;
        for (integer k = 0; k < SHARES; k=k+1) begin
			XxDI[k] = 0;
            RandomB = $random;
            RandomZ = $random;
		end
		#T;
        
        for (integer i = 0; i < 256; i = i + 1) begin
            XxDI[1] = i;
            for (integer j = 0; j < 256; j = j + 1) begin
                XxDI[0] = j;
                X = 4'b0000;
                Q = 4'b0000;
                RandomB = $random;
                RandomZ = $random;
                for (integer k = 0; k < SHARES; k = k + 1) begin
                    X = X ^ XxDI[k];
                    Q = Q ^ QxDO[k];
                end
                #T;
            end
        end
        #T;
        
    end


endmodule