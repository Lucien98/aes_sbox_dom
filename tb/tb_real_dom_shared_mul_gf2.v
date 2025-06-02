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
module tb_real_dom_shared_mul_gf2 ();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam N = 2;
    localparam PIPELINED = 1;
    localparam FIRST_ORDER_OPTIMIZATION = 1; // change it to test different cases
    localparam SHARES = 3; // change it to test different cases

    // General signals
	reg ClkxCI;
	reg RstxBI;

	reg [1:0] XxDI [SHARES-1 : 0];
	reg [1:0] YxDI [SHARES-1 : 0];
	wire [1:0] QxDO [SHARES-1 : 0];

	wire [2*SHARES-1 : 0] _XxDI;
	wire [2*SHARES-1 : 0] _YxDI;
	wire [SHARES*(SHARES-1)-1 : 0] _ZxDI;
    wire [2*SHARES-1 : 0] _BxDI;
	wire [2*SHARES-1 : 0] _QxDO;

    for (genvar i = 0; i < SHARES; i=i+1) begin
        for (genvar j = 0; j < 2; j=j+1) begin
            assign _XxDI[i*2+j] = XxDI[i][j];
            assign _YxDI[i*2+j] = YxDI[i][j];
            assign _BxDI[i*2+j] = 0;
            assign QxDO[i][j] = _QxDO[i*2+j];
        end
    end

    for (genvar i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
        for (genvar j = 0; j < 2; j=j+1) begin
            assign _ZxDI[i*2+j] = 0;
        end
    end

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(FIRST_ORDER_OPTIMIZATION), .SHARES(SHARES))
    inst_real_dom_shared_mul_gf2 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_XxDI),
        ._YxDI(_YxDI),
        ._ZxDI(_ZxDI),
        ._BxDI(_BxDI),
        ._QxDO(_QxDO)
    );

    // Create clock
	always@(*) #Td ClkxCI<=~ClkxCI;

	initial begin
        ClkxCI = 0;
		RstxBI = 0;
        for (integer k = 0; k < SHARES; k=k+1) begin
			XxDI[k] <= 0;
			YxDI[k] <= 0;
		end
		#T;
		RstxBI = 1;
		#T;

        //alternative version
		for (integer i = 0; i < 2**N; i = i+1) begin
			for (integer j = 0; j < 2**N; j = j+1) begin
                XxDI[0] <= i;
                YxDI[0] <= j;
                for (integer k = 1; k < SHARES; k=k+1) begin
                    XxDI[k] <= 0;
                    YxDI[k] <= 0;
                    /* code */
                end
				#T;
			end
		end
    end


endmodule