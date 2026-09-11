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

module real_dom_shared_mul_gf2 #(
    parameter PIPELINED = 1, // 1: yes, 0: no
    parameter FIRST_ORDER_OPTIMIZATION = 1, // 1: yes, 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    // RstxBI,
    _XxDI,
    _YxDI,
    _ZxDI,
    _BxDI,
    _QxDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);

input ClkxCI;
// input RstxBI;
input [2*SHARES-1 : 0] _XxDI;
input [2*SHARES-1 : 0] _YxDI;
input [SHARES*(SHARES-1)-1 : 0] _ZxDI;
input [2*blind_n_rnd-1 : 0] _BxDI;
output [2*SHARES-1 : 0] _QxDO;

wire [1:0] XxDI [SHARES-1 : 0];
wire [1:0] YxDI [SHARES-1 : 0];
wire [1:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [1:0] BxDI [SHARES-1 : 0];
wire [1:0] QxDO [SHARES-1 : 0];

genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*2+j];
        assign YxDI[i][j] = _YxDI[i*2+j];
        assign _QxDO[i*2+j] = QxDO[i][j];
    end
end

if (SHARES == 2) begin
    // The first-order DOM-dep construction uses one field element b.
    // Mirror it in both array slots so the non-specialized branch remains
    // well-defined when FIRST_ORDER_OPTIMIZATION is disabled for testing.
    for (j = 0; j < 2; j=j+1) begin
        assign BxDI[0][j] = _BxDI[j];
        assign BxDI[1][j] = _BxDI[j];
    end
end
else begin
    for (i = 0; i < SHARES; i=i+1) begin
        for (j = 0; j < 2; j=j+1) begin
            assign BxDI[i][j] = _BxDI[i*2+j];
        end
    end
end

for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign ZxDI[i][j] = _ZxDI[i*2+j];
    end
end

// -----------------------------------------------------------------------------
// First-order optimized DOM-dep.
//
// The two linear-in-X products
//     x_i*y_i  and  x_i*(y_j+b)
// are merged into a single field multiplication
//     x_i*(y_i + y_j + b).
// The registered cross-domain term x_i*b + z is kept unchanged.
// -----------------------------------------------------------------------------
if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin : gen_first_order
    reg  [1:0] BlindedYxDP [SHARES-1 : 0];
    wire [1:0] BlindedYxDN [SHARES-1 : 0];
    reg  [1:0] XxDP [SHARES-1 : 0];
    reg  [1:0] YxDP [SHARES-1 : 0];
    wire [1:0] XxD [SHARES-1 : 0];
    wire [1:0] YxD [SHARES-1 : 0];

    wire [1:0] XtimesMergedYxD [SHARES-1 : 0];
    wire [1:0] XtimesBxD [SHARES-1 : 0];
    wire [1:0] XtimesBRemaskedxDN [SHARES-1 : 0];
    reg  [1:0] XtimesBRemaskedxDP [SHARES-1 : 0];

    assign BlindedYxDN[0] = YxDI[1] ^ BxDI[0];
    assign BlindedYxDN[1] = YxDI[0] ^ BxDI[0];

    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign XxD[i] = XxDP[i];
            assign YxD[i] = YxDP[i];
        end
    end
    else begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign XxD[i] = XxDI[i];
            assign YxD[i] = YxDI[i];
        end
    end

    for (i = 0; i < SHARES; i=i+1) begin
        gf2_mul #(.N(2)) x_times_merged_y (
            .AxDI(XxD[i]),
            .BxDI(YxD[i] ^ BlindedYxDP[i]),
            .QxDO(XtimesMergedYxD[i])
        );

        gf2_mul #(.N(2)) x_times_b (
            .AxDI(XxDI[i]),
            .BxDI(BxDI[0]),
            .QxDO(XtimesBxD[i])
        );

        assign XtimesBRemaskedxDN[i] = XtimesBxD[i] ^ ZxDI[0];
        assign QxDO[i] = XtimesMergedYxD[i] ^ XtimesBRemaskedxDP[i];
    end

    always @(posedge ClkxCI) begin : proc_first_order_registers
        integer k;
        for (k = 0; k < SHARES; k=k+1) begin
            BlindedYxDP[k] <= BlindedYxDN[k];
            XtimesBRemaskedxDP[k] <= XtimesBRemaskedxDN[k];
            if (PIPELINED == 1) begin
                XxDP[k] <= XxDI[k];
                YxDP[k] <= YxDI[k];
            end
        end
    end
end

// -----------------------------------------------------------------------------
// General optimized DOM-dep (SHARES > 2 in the AES construction).
//
// Let s = XOR_j [y_j + b_j].  Instead of separately computing
//     x_i*s + x_i*b_i,
// use one multiplier
//     x_i*(s + [b_i]).
// Hence only the SHARES*(SHARES-1) cross-domain x_i*b_j products (i != j)
// and SHARES merged domain products remain: SHARES^2 field multipliers total.
// Registering b_i replaces the removed diagonal x_i*b_i result register, so
// the pipeline boundary and the number of stored field elements are preserved.
// -----------------------------------------------------------------------------
if (FIRST_ORDER_OPTIMIZATION == 0 || SHARES > 2) begin : gen_general
    reg [1:0] BlindedYxDP [SHARES-1 : 0];
    reg [1:0] BxDP [SHARES-1 : 0];
    reg [1:0] XxDP [SHARES-1 : 0];
    wire [1:0] XxD [SHARES-1 : 0];

    reg [1:0] SumBlindedY;
    wire [1:0] MergedYxD [SHARES-1 : 0];
    wire [1:0] DomainTermxD [SHARES-1 : 0];

    wire [1:0] XiMulBj [SHARES*SHARES-1 : 0];
    wire [1:0] CrossRemaskedxDN [SHARES*SHARES-1 : 0];
    reg  [1:0] CrossRemaskedxDP [SHARES*SHARES-1 : 0];
    reg  [1:0] ResultxD [SHARES-1 : 0];

    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign XxD[i] = XxDP[i];
        end
    end
    else begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign XxD[i] = XxDI[i];
        end
    end

    always @(*) begin : proc_sum_blinded_y
        integer k;
        SumBlindedY = 2'b00;
        for (k = 0; k < SHARES; k=k+1) begin
            SumBlindedY = SumBlindedY ^ BlindedYxDP[k];
        end
    end

    for (i = 0; i < SHARES; i=i+1) begin
        assign MergedYxD[i] = SumBlindedY ^ BxDP[i];
        gf2_mul #(.N(2)) merged_domain_mul (
            .AxDI(XxD[i]),
            .BxDI(MergedYxD[i]),
            .QxDO(DomainTermxD[i])
        );
    end

    for (i = 0; i < SHARES; i=i+1) begin
        for (j = 0; j < SHARES; j=j+1) begin
            if (i != j) begin : gen_cross_domain
                gf2_mul #(.N(2)) cross_domain_mul (
                    .AxDI(XxDI[i]),
                    .BxDI(BxDI[j]),
                    .QxDO(XiMulBj[SHARES*i+j])
                );

                if (j > i) begin
                    assign CrossRemaskedxDN[SHARES*i+j] =
                        XiMulBj[SHARES*i+j] ^ ZxDI[i + j*(j-1)/2];
                end
                else begin
                    assign CrossRemaskedxDN[SHARES*i+j] =
                        XiMulBj[SHARES*i+j] ^ ZxDI[j + i*(i-1)/2];
                end
            end
        end
    end

    always @(*) begin : proc_compress
        integer k;
        integer l;
        for (k = 0; k < SHARES; k=k+1) begin
            ResultxD[k] = DomainTermxD[k];
            for (l = 0; l < SHARES; l=l+1) begin
                if (k != l) begin
                    ResultxD[k] = ResultxD[k] ^ CrossRemaskedxDP[SHARES*k+l];
                end
            end
        end
    end

    for (i = 0; i < SHARES; i=i+1) begin
        assign QxDO[i] = ResultxD[i];
    end

    always @(posedge ClkxCI) begin : proc_general_registers
        integer k;
        integer l;
        for (k = 0; k < SHARES; k=k+1) begin
            BlindedYxDP[k] <= YxDI[k] ^ BxDI[k];
            BxDP[k] <= BxDI[k];
            if (PIPELINED == 1) begin
                XxDP[k] <= XxDI[k];
            end
            for (l = 0; l < SHARES; l=l+1) begin
                if (k != l) begin
                    CrossRemaskedxDP[SHARES*k+l] <= CrossRemaskedxDN[SHARES*k+l];
                end
            end
        end
    end
end

endmodule
