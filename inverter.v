module inverter #(
    parameter VARIANT = 1, // 1: Masked
    parameter PIPELINED = 1, // 1: yes
    // Only for pipelined variant
    parameter EIGHT_STAGED_SBOX = 0, // 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    RstxBI,
    // masked input
    _XxDI,
    // Fresh masks
    _Zmul1xDI,
    _Zmul2xDI,
    _Zmul3xDI,
    _Bmul1xDI,
    _Bmul2xDI,
    _Bmul3xDI,
    // Outputs
    _QxDO
);
input ClkxCI;
input RstxBI;
input [4*SHARES-1 : 0] _XxDI;
input [SHARES*(SHARES-1)-1 : 0] _Zmul1xDI;
input [SHARES*(SHARES-1)-1 : 0] _Zmul2xDI;
input [SHARES*(SHARES-1)-1 : 0] _Zmul3xDI;
input [2*SHARES-1 : 0] _Bmul1xDI;
input [2*SHARES-1 : 0] _Bmul2xDI;
input [2*SHARES-1 : 0] _Bmul3xDI;
output [4*SHARES-1 : 0] _QxDO;

wire [3:0] XxDI [SHARES-1 : 0];
wire [3:0] QxDO [SHARES-1 : 0];

for (genvar i = 0; i < SHARES; i=i+1) begin
    for (genvar j = 0; j < 4; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*4+j];
        assign _QxDO[i*4+j] = QxDO[i][j];
    end
end


// Shares
wire [1:0] A [SHARES-1:0]; // MSBits of input
wire [1:0] B [SHARES-1:0]; // LSBits of input
wire [2*SHARES-1 : 0] _A;
wire [2*SHARES-1 : 0] _B;
// Intermediates
wire [1:0] AmulBxD [SHARES-1:0]; // A x B
wire [2*SHARES-1 : 0] _AmulBxD;
wire [1:0] AmulExD [SHARES-1:0]; // A x E
wire [2*SHARES-1 : 0] _AmulExD;
wire [1:0] BmulExD [SHARES-1:0]; // B x E
wire [2*SHARES-1 : 0] _BmulExD;
wire [1:0] ExD [SHARES-1:0]; // E
wire [2*SHARES-1 : 0] _ExD;
wire [1:0] CxD [SHARES-1:0]; // C
// Pipelining
reg [1:0] AxDP [SHARES-1:0]; // MSBits
wire [2*SHARES-1 : 0] _AxDP;
reg [1:0] BxDP [SHARES-1:0]; // LSBits
wire [2*SHARES-1 : 0] _BxDP;
reg [1:0] CxDP [SHARES-1:0]; // C

for (genvar i = 0; i < SHARES; i=i+1) begin
    for (genvar j = 0; j < 2; j=j+1) begin
        assign _A[i*2+j] = A[i][j];
        assign _B[i*2+j] = B[i][j];
        assign AmulBxD[i][j] = _AmulBxD[i*2+j];
        assign AmulExD[i][j] = _AmulExD[i*2+j];
        assign BmulExD[i][j] = _BmulExD[i*2+j];
        assign _ExD[i*2+j] = ExD[i][j];
        assign _AxDP[i*2+j] = AxDP[i][j];
        assign _BxDP[i*2+j] = BxDP[i][j];
    end
end

// For 8 staged Sbox only
// wire [1:0] pipelinedAxDP [SHARES-1:0]; // MSBits
// wire [1:0] pipelinedBxDP [SHARES-1:0]; // LSBits
// wire [1:0] ExDP [SHARES-1:0]; // E pipl.

// General
for (genvar i = 0; i < SHARES; i = i + 1) begin
    // split GF2^4 element in two GF2^2
    assign A[i][1] = XxDI[i][3];
    assign A[i][0] = XxDI[i][2];
    assign B[i][1] = XxDI[i][1];
    assign B[i][0] = XxDI[i][0];
end

// Masked Inverter for 5 staged Sbox
if (VARIANT == 1 && PIPELINED == 1 && EIGHT_STAGED_SBOX == 0) begin
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            // iterate over shares
            for (integer i = 0; i < SHARES; i = i + 1) begin
                AxDP[i] = 2'b00;
                BxDP[i] = 2'b00;
                CxDP[i] = 2'b00;
            end
        end
        else begin // rising clock edge
            // iterate over shares
            for (integer i = 0; i < SHARES; i = i + 1) begin
                AxDP[i] = A[i];
                BxDP[i] = B[i];
                CxDP[i] = CxD[i];
            end
        end
    end

    wire [1:0] d [SHARES-1 : 0];
    wire [1:0] dm [SHARES-1 : 0];
    // iterate over shares
    for (genvar i = 0; i < SHARES; i = i + 1) begin
        // xor and ^2
        assign d[i] = {(A[i][0] ^ B[i][0]), (A[i][1] ^ B[i][1])};
        // scale
        assign CxD[i] = {d[i][0], (d[i][1] ^ d[i][0])};
        // (c+d)^2
        assign ExD[i] = {(CxDP[i][0] ^ AmulBxD[i][0]), (CxDP[i][1] ^ AmulBxD[i][1])};
        // Output
        assign QxDO[i] = {BmulExD[i], AmulExD[i]};
    end

    // Multipliers
    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    a_mul_b (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_A),
        ._YxDI(_B),
        ._ZxDI(_Zmul1xDI),
        ._BxDI(_Bmul1xDI),
        ._QxDO(_AmulBxD)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    a_mul_e (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_AxDP),
        ._YxDI(_ExD),
        ._ZxDI(_Zmul2xDI),
        ._BxDI(_Bmul2xDI),
        ._QxDO(_AmulExD)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    b_mul_e (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_BxDP),
        ._YxDI(_ExD),
        ._ZxDI(_Zmul3xDI),
        ._BxDI(_Bmul3xDI),
        ._QxDO(_BmulExD)
    );
end


    
endmodule