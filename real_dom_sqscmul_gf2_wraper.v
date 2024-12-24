module real_dom_sqscmul_gf2_wraper #(
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
    _Bmul1xDI,
    // Outputs
    _QxDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);

input ClkxCI;
input RstxBI;
input [4*SHARES-1 : 0] _XxDI;
input [SHARES*(SHARES-1)-1 : 0] _Zmul1xDI;
// input [SHARES*(SHARES-1)-1 : 0] _Zmul2xDI;
// input [SHARES*(SHARES-1)-1 : 0] _Zmul3xDI;
input [2*blind_n_rnd-1 : 0] _Bmul1xDI;
// input [2*blind_n_rnd-1 : 0] _Bmul2xDI;
// input [2*blind_n_rnd-1 : 0] _Bmul3xDI;
output [2*SHARES-1 : 0] _QxDO;

wire [3:0] XxDI [SHARES-1 : 0];
wire [1:0] QxDO [SHARES-1 : 0];
wire [3:0] X;
wire [1:0] Q;
assign X=XxDI[1] ^ XxDI[0];
assign Q=QxDO[1] ^ QxDO[0];
genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*4+j];
    end
end

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign _QxDO[i*2+j] = QxDO[i][j];
    end
end

// Shares
wire [1:0] A [SHARES-1:0]; // MSBits of input
wire [1:0] B [SHARES-1:0]; // LSBits of input
wire [2*SHARES-1 : 0] _A;
wire [2*SHARES-1 : 0] _B;
// Intermediates
wire [1:0] AsqscmulBxD [SHARES-1:0]; // A sqsc B + A x B = E
wire [2*SHARES-1 : 0] _AsqscmulBxD;

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign _A[i*2+j] = A[i][j];
        assign _B[i*2+j] = B[i][j];
        assign AsqscmulBxD[i][j] = _AsqscmulBxD[i*2+j];
    end
end


// General
for (i = 0; i < SHARES; i = i + 1) begin
    // split GF2^4 element in two GF2^2
    assign A[i][1] = XxDI[i][3];
    assign A[i][0] = XxDI[i][2];
    assign B[i][1] = XxDI[i][1];
    assign B[i][0] = XxDI[i][0];
end

// Masked Inverter for 5 staged Sbox
if (VARIANT == 1 && PIPELINED == 1 && EIGHT_STAGED_SBOX == 0) begin

    for (i = 0; i < SHARES; i = i + 1) begin
        // Output
        assign QxDO[i] = {AsqscmulBxD[i][1], AsqscmulBxD[i][0]};
    end

    // Multipliers
    real_dom_shared_sqscmul_gf2 # (.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    a_sqscmul_b
    (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_A),
        ._YxDI(_B),
        ._ZxDI(_Zmul1xDI),
        ._BxDI(_Bmul1xDI),
        ._QxDO(_AsqscmulBxD)
    );

end


    
endmodule