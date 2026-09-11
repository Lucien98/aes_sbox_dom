// 
// Copyright (C) 2025 Feng Zhou
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

module real_dom_shared_mul_gf2_paired #(
    parameter PIPELINED = 1, // 1: yes, 0: no
    parameter FIRST_ORDER_OPTIMIZATION = 1, // 1: yes, 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    // RstxBI,
    _X1xDI,
    _X2xDI,
    _YxDI,
    _Z1xDI,
    _Z2xDI,
    _BxDI,
    _Q1xDO,
    _Q2xDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);

input ClkxCI;
// input RstxBI;
input [2*SHARES-1 : 0] _X1xDI;
input [2*SHARES-1 : 0] _X2xDI;
input [2*SHARES-1 : 0] _YxDI;
input [SHARES*(SHARES-1)-1 : 0] _Z1xDI;
input [SHARES*(SHARES-1)-1 : 0] _Z2xDI;
input [2*blind_n_rnd-1 : 0] _BxDI;
output [2*SHARES-1 : 0] _Q1xDO;
output [2*SHARES-1 : 0] _Q2xDO;

wire [1:0] X1xDI [SHARES-1 : 0];
wire [1:0] X2xDI [SHARES-1 : 0];
wire [1:0] YxDI [SHARES-1 : 0];
wire [1:0] Z1xDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [1:0] Z2xDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [1:0] BxDI [SHARES-1 : 0];
wire [1:0] Q1xDO [SHARES-1 : 0];
wire [1:0] Q2xDO [SHARES-1 : 0];

genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign X1xDI[i][j] = _X1xDI[i*2+j];
        assign X2xDI[i][j] = _X2xDI[i*2+j];
        assign YxDI[i][j] = _YxDI[i*2+j];
        assign _Q1xDO[i*2+j] = Q1xDO[i][j];
        assign _Q2xDO[i*2+j] = Q2xDO[i][j];
    end
end

if (SHARES == 2) begin
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
        assign Z1xDI[i][j] = _Z1xDI[i*2+j];
        assign Z2xDI[i][j] = _Z2xDI[i*2+j];
    end
end

// The paired multiplier shares the blinded Y and blinding-value registers.
// Each X operand still has its own remasked cross-domain terms.

if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin : gen_first_order
    reg  [1:0] BlindedYxDP [SHARES-1 : 0];
    wire [1:0] BlindedYxDN [SHARES-1 : 0];
    reg  [1:0] X1xDP [SHARES-1 : 0];
    reg  [1:0] X2xDP [SHARES-1 : 0];
    reg  [1:0] YxDP [SHARES-1 : 0];
    wire [1:0] X1xD [SHARES-1 : 0];
    wire [1:0] X2xD [SHARES-1 : 0];
    wire [1:0] YxD [SHARES-1 : 0];

    wire [1:0] X1timesMergedYxD [SHARES-1 : 0];
    wire [1:0] X2timesMergedYxD [SHARES-1 : 0];
    wire [1:0] X1timesBxD [SHARES-1 : 0];
    wire [1:0] X2timesBxD [SHARES-1 : 0];
    wire [1:0] X1timesBRemaskedxDN [SHARES-1 : 0];
    wire [1:0] X2timesBRemaskedxDN [SHARES-1 : 0];
    reg  [1:0] X1timesBRemaskedxDP [SHARES-1 : 0];
    reg  [1:0] X2timesBRemaskedxDP [SHARES-1 : 0];

    assign BlindedYxDN[0] = YxDI[1] ^ BxDI[0];
    assign BlindedYxDN[1] = YxDI[0] ^ BxDI[0];

    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign X1xD[i] = X1xDP[i];
            assign X2xD[i] = X2xDP[i];
            assign YxD[i] = YxDP[i];
        end
    end
    else begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign X1xD[i] = X1xDI[i];
            assign X2xD[i] = X2xDI[i];
            assign YxD[i] = YxDI[i];
        end
    end

    for (i = 0; i < SHARES; i=i+1) begin
        // This merge was already used by the previous paired first-order RTL.
        gf2_mul #(.N(2)) x1_times_merged_y (
            .AxDI(X1xD[i]),
            .BxDI(YxD[i] ^ BlindedYxDP[i]),
            .QxDO(X1timesMergedYxD[i])
        );
        gf2_mul #(.N(2)) x2_times_merged_y (
            .AxDI(X2xD[i]),
            .BxDI(YxD[i] ^ BlindedYxDP[i]),
            .QxDO(X2timesMergedYxD[i])
        );

        gf2_mul #(.N(2)) x1_times_b (
            .AxDI(X1xDI[i]),
            .BxDI(BxDI[0]),
            .QxDO(X1timesBxD[i])
        );
        gf2_mul #(.N(2)) x2_times_b (
            .AxDI(X2xDI[i]),
            .BxDI(BxDI[0]),
            .QxDO(X2timesBxD[i])
        );

        assign X1timesBRemaskedxDN[i] = X1timesBxD[i] ^ Z1xDI[0];
        assign X2timesBRemaskedxDN[i] = X2timesBxD[i] ^ Z2xDI[0];
        assign Q1xDO[i] = X1timesMergedYxD[i] ^ X1timesBRemaskedxDP[i];
        assign Q2xDO[i] = X2timesMergedYxD[i] ^ X2timesBRemaskedxDP[i];
    end

    always @(posedge ClkxCI) begin : proc_first_order_registers
        integer k;
        for (k = 0; k < SHARES; k=k+1) begin
            BlindedYxDP[k] <= BlindedYxDN[k];
            X1timesBRemaskedxDP[k] <= X1timesBRemaskedxDN[k];
            X2timesBRemaskedxDP[k] <= X2timesBRemaskedxDN[k];
            if (PIPELINED == 1) begin
                X1xDP[k] <= X1xDI[k];
                X2xDP[k] <= X2xDI[k];
                YxDP[k] <= YxDI[k];
            end
        end
    end
end

if (FIRST_ORDER_OPTIMIZATION == 0 || SHARES > 2) begin : gen_general
    reg [1:0] BlindedYxDP [SHARES-1 : 0];
    reg [1:0] BxDP [SHARES-1 : 0];
    reg [1:0] X1xDP [SHARES-1 : 0];
    reg [1:0] X2xDP [SHARES-1 : 0];
    wire [1:0] X1xD [SHARES-1 : 0];
    wire [1:0] X2xD [SHARES-1 : 0];

    reg [1:0] SumBlindedY;
    wire [1:0] MergedYxD [SHARES-1 : 0];
    wire [1:0] DomainTerm1xD [SHARES-1 : 0];
    wire [1:0] DomainTerm2xD [SHARES-1 : 0];

    wire [1:0] X1iMulBj [SHARES*SHARES-1 : 0];
    wire [1:0] X2iMulBj [SHARES*SHARES-1 : 0];
    wire [1:0] Cross1RemaskedxDN [SHARES*SHARES-1 : 0];
    wire [1:0] Cross2RemaskedxDN [SHARES*SHARES-1 : 0];
    reg  [1:0] Cross1RemaskedxDP [SHARES*SHARES-1 : 0];
    reg  [1:0] Cross2RemaskedxDP [SHARES*SHARES-1 : 0];
    reg  [1:0] Result1xD [SHARES-1 : 0];
    reg  [1:0] Result2xD [SHARES-1 : 0];

    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign X1xD[i] = X1xDP[i];
            assign X2xD[i] = X2xDP[i];
        end
    end
    else begin
        for (i = 0; i < SHARES; i=i+1) begin
            assign X1xD[i] = X1xDI[i];
            assign X2xD[i] = X2xDI[i];
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
        gf2_mul #(.N(2)) merged_domain_mul_1 (
            .AxDI(X1xD[i]),
            .BxDI(MergedYxD[i]),
            .QxDO(DomainTerm1xD[i])
        );
        gf2_mul #(.N(2)) merged_domain_mul_2 (
            .AxDI(X2xD[i]),
            .BxDI(MergedYxD[i]),
            .QxDO(DomainTerm2xD[i])
        );
    end

    for (i = 0; i < SHARES; i=i+1) begin
        for (j = 0; j < SHARES; j=j+1) begin
            if (i != j) begin : gen_cross_domain
                gf2_mul #(.N(2)) cross_domain_mul_1 (
                    .AxDI(X1xDI[i]),
                    .BxDI(BxDI[j]),
                    .QxDO(X1iMulBj[SHARES*i+j])
                );
                gf2_mul #(.N(2)) cross_domain_mul_2 (
                    .AxDI(X2xDI[i]),
                    .BxDI(BxDI[j]),
                    .QxDO(X2iMulBj[SHARES*i+j])
                );

                if (j > i) begin
                    assign Cross1RemaskedxDN[SHARES*i+j] =
                        X1iMulBj[SHARES*i+j] ^ Z1xDI[i + j*(j-1)/2];
                    assign Cross2RemaskedxDN[SHARES*i+j] =
                        X2iMulBj[SHARES*i+j] ^ Z2xDI[i + j*(j-1)/2];
                end
                else begin
                    assign Cross1RemaskedxDN[SHARES*i+j] =
                        X1iMulBj[SHARES*i+j] ^ Z1xDI[j + i*(i-1)/2];
                    assign Cross2RemaskedxDN[SHARES*i+j] =
                        X2iMulBj[SHARES*i+j] ^ Z2xDI[j + i*(i-1)/2];
                end
            end
        end
    end

    always @(*) begin : proc_compress
        integer k;
        integer l;
        for (k = 0; k < SHARES; k=k+1) begin
            Result1xD[k] = DomainTerm1xD[k];
            Result2xD[k] = DomainTerm2xD[k];
            for (l = 0; l < SHARES; l=l+1) begin
                if (k != l) begin
                    Result1xD[k] = Result1xD[k] ^ Cross1RemaskedxDP[SHARES*k+l];
                    Result2xD[k] = Result2xD[k] ^ Cross2RemaskedxDP[SHARES*k+l];
                end
            end
        end
    end

    for (i = 0; i < SHARES; i=i+1) begin
        assign Q1xDO[i] = Result1xD[i];
        assign Q2xDO[i] = Result2xD[i];
    end

    always @(posedge ClkxCI) begin : proc_general_registers
        integer k;
        integer l;
        for (k = 0; k < SHARES; k=k+1) begin
            BlindedYxDP[k] <= YxDI[k] ^ BxDI[k];
            BxDP[k] <= BxDI[k];
            if (PIPELINED == 1) begin
                X1xDP[k] <= X1xDI[k];
                X2xDP[k] <= X2xDI[k];
            end
            for (l = 0; l < SHARES; l=l+1) begin
                if (k != l) begin
                    Cross1RemaskedxDP[SHARES*k+l] <= Cross1RemaskedxDN[SHARES*k+l];
                    Cross2RemaskedxDP[SHARES*k+l] <= Cross2RemaskedxDN[SHARES*k+l];
                end
            end
        end
    end
end

endmodule
