module real_dom_shared_mul_gf2_quadruple #(
    parameter PIPELINED = 1, // 1: yes, 0: no
    parameter FIRST_ORDER_OPTIMIZATION = 1, // 1: yes, 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    // RstxBI,
    _X1xDI,
    _X2xDI,
    _X3xDI,
    _X4xDI,
    _YxDI,
    _Z1xDI,
    _Z2xDI,
    _Z3xDI,
    _Z4xDI,
    _BxDI,
    _Q1xDO,
    _Q2xDO,
    _Q3xDO,
    _Q4xDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);

input ClkxCI;
// input RstxBI;
input [2*SHARES-1 : 0] _YxDI;
input [2*blind_n_rnd-1 : 0] _BxDI;

wire [1:0] YxDI [SHARES-1 : 0];
wire [1:0] BxDI [blind_n_rnd-1 : 0];

genvar i;
genvar j;

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign YxDI[i][j] = _YxDI[i*2+j];
    end
end

if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin
    for (i = 0; i < SHARES-1; i=i+1) begin
        for (j = 0; j < 2; j=j+1) begin
            assign BxDI[i][j] = _BxDI[i*2+j];
        end
    end
end
else begin
    for (i = 0; i < SHARES; i=i+1) begin
        for (j = 0; j < 2; j=j+1) begin
            assign BxDI[i][j] = _BxDI[i*2+j];
        end
    end    
end


// Intermediates
// Blinded Y values
reg [1:0] BlindedYxDN [SHARES-1 : 0];
reg [1:0] BlindedYxDP [SHARES-1 : 0];
// Sum of blinded Y shares
reg [1:0] SumBlindedYxD;
// x *( sum(y+b) ) signal

// Y pipelined
reg [1:0] YxDP [SHARES-1 : 0];
// X and Y multiplier inputs depending on pipelinign selection
wire [1:0] YxD [SHARES-1 : 0];

`include "final4_1.v"
`include "final4_2.v"
`include "final4_3.v"
`include "final4_4.v"


// First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin

    always @(*) begin
        BlindedYxDN[1] = YxDI[0] ^ BxDI[0];
        BlindedYxDN[0] = YxDI[1] ^ BxDI[0];
    end

    // Select inputs for multipliers depending if pipelining is used
    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign YxD[i][0] = YxDP[i][0];
            assign YxD[i][1] = YxDP[i][1];
        end
    end
    else begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign YxD[i][0] = YxDI[i][0];
            assign YxD[i][1] = YxDI[i][1];
        end
    end
end


reg [1:0] SumBlindedY;

// NO First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 0 || SHARES > 2) begin
    integer k;
    always @(*) begin
        for (k = 0; k < SHARES; k = k + 1) begin
            BlindedYxDN[k] = BlindedYxDP[k];
        end
        SumBlindedY = 2'b00;
        // per share
        for (k = 0; k < SHARES; k = k + 1) begin
            BlindedYxDN[k] = YxDI[k] ^ BxDI[k];
            // Sum of blinded Y
            SumBlindedY = SumBlindedY ^ BlindedYxDP[k];
        end
        SumBlindedYxD = SumBlindedY;
    end

end


// General stuff used for all variants:
// Use pipelining --> X needs to be registered
if (PIPELINED == 1) begin
    always @(posedge ClkxCI/* or negedge RstxBI*/) begin : proc_
    // always @(posedge ClkxCI) begin : proc_
        integer k;
        // if (~RstxBI) begin // asynchronous reset (active low)
        //     for (k = 0; k < SHARES; k = k + 1) begin
        //         // XxDP[k] = 2'b00;
        //         YxDP[k] = 2'b00;
        //     end
        // end
        // else begin // rising clock edge
            for (k = 0; k < SHARES; k = k + 1) begin
                // XxDP[k] = XxDI[k];
                YxDP[k] = YxDI[k];
            end
        // end
    end
end

// Blinding register process
always @(posedge ClkxCI/* or negedge RstxBI*/) begin : proc_
    integer k;
    // if (~RstxBI) begin // asynchronous reset (active low)
    //     for (k = 0; k < SHARES; k = k + 1) begin
    //         BlindedYxDP[k] = 2'b00;
    //     end
    // end
    // else begin // rising clock edge
        for (k = 0; k < SHARES; k = k + 1) begin
            BlindedYxDP[k] = BlindedYxDN[k];
        end
    // end
end


    
endmodule