module inverter #(
    parameter VARIANT = 1, // 1: Masked
    parameter PIPELINED = 1, // 1: yes
    // Only for pipelined variant
    parameter SHARES = 2
) (
    ClkxCI,
    // RstxBI,
    // masked input
    _XxDI,
    // Fresh masks
    _Zmul1xDI,
    _Zmul2xDI,
    _Zmul3xDI,
    _Bmul1xDI,
    // _Bmul2xDI,
// `ifndef RAND_OPT
//     _Bmul3xDI,
// `endif
    // Outputs
    _QxDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);
localparam invbcoeff = _invbcoeff(SHARES);

input ClkxCI;
// input RstxBI;
input [4*SHARES-1 : 0] _XxDI;
input [SHARES*(SHARES-1)-1 : 0] _Zmul1xDI;
input [SHARES*(SHARES-1)-1 : 0] _Zmul2xDI;
input [SHARES*(SHARES-1)-1 : 0] _Zmul3xDI;
input [invbcoeff*blind_n_rnd-1 : 0] _Bmul1xDI;
output [4*SHARES-1 : 0] _QxDO;

wire [3:0] XxDI [SHARES-1 : 0];
wire [3:0] QxDO [SHARES-1 : 0];

genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
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
wire [1:0] AsqscmulBxD [SHARES-1:0]; // A sqsc B + A x B = E
wire [2*SHARES-1 : 0] _AsqscmulBxD;
wire [1:0] AmulExD [SHARES-1:0]; // A x E
wire [2*SHARES-1 : 0] _AmulExD;
wire [1:0] BmulExD [SHARES-1:0]; // B x E
wire [2*SHARES-1 : 0] _BmulExD;
wire [1:0] CxD [SHARES-1:0]; // C
// Pipelining
reg [1:0] AxDP [SHARES-1:0]; // MSBits
wire [2*SHARES-1 : 0] _AxDP;
reg [1:0] BxDP [SHARES-1:0]; // LSBits
wire [2*SHARES-1 : 0] _BxDP;
reg [1:0] CxDP [SHARES-1:0]; // C

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign _A[i*2+j] = A[i][j];
        assign _B[i*2+j] = B[i][j];
        // assign AmulBxD[i][j] = _AmulBxD[i*2+j];
        assign AsqscmulBxD[i][j] = _AsqscmulBxD[i*2+j];
        assign AmulExD[i][j] = _AmulExD[i*2+j];
        assign BmulExD[i][j] = _BmulExD[i*2+j];
        // assign _ExD[i*2+j] = ExD[i][j];
        assign _AxDP[i*2+j] = AxDP[i][j];
        assign _BxDP[i*2+j] = BxDP[i][j];
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
if (VARIANT == 1 && PIPELINED == 1) begin
    always @(posedge ClkxCI /*or negedge RstxBI*/) begin : proc_
        integer k;
        // if (~RstxBI) begin // asynchronous reset (active low)
        //     // iterate over shares
        //     for (k = 0; k < SHARES; k = k + 1) begin
        //         AxDP[k] = 2'b00;
        //         BxDP[k] = 2'b00;
        //         CxDP[k] = 2'b00;
        //     end
        // end
        // else begin // rising clock edge
            // iterate over shares
            for (k = 0; k < SHARES; k = k + 1) begin
                AxDP[k] = A[k];
                BxDP[k] = B[k];
                CxDP[k] = CxD[k];
            end
        // end
    end

    for (i = 0; i < SHARES; i = i + 1) begin
        // Output
        assign QxDO[i] = {BmulExD[i], AmulExD[i]};
    end

`ifndef OPTO1O2
    `ifndef RAND_OPT
        /*
        0: 2 independent dom-dep mul_gf2; 1 dom-dep sqscmul_gf2
        1: 2 dom-dep mul_gf2 shares the same blinded Y; 1 dom-dep sqscmul_gf2
        2: 2 dom-indep; 1 sni sqscmul_gf2
        */
        localparam inverter_type = 0;
    `else 
        localparam inverter_type = 1;
    `endif
`else 
    `ifndef RAND_OPT
        localparam inverter_type = SHARES <= 3 ? 2 : 0;
    `else 
        localparam inverter_type = SHARES <= 3 ? 2 : 1;
    `endif
`endif

if (inverter_type == 2) begin
    shared_sqscmul_gf_sni # (.PIPELINED(PIPELINED), .SHARES(SHARES), .N(2))
    a_sqscmul_b
    (
        .ClkxCI(ClkxCI),
        ._XxDI(_A),
        ._YxDI(_B),
        ._ZxDI({_Zmul1xDI,_Bmul1xDI}),
        ._QxDO(_AsqscmulBxD)
    );

end
else begin

    // Multipliers
    real_dom_shared_sqscmul_gf2 # (.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    a_sqscmul_b
    (
        .ClkxCI(ClkxCI),
        // .RstxBI(RstxBI),
        ._XxDI(_A),
        ._YxDI(_B),
        ._ZxDI(_Zmul1xDI),
        ._BxDI(_Bmul1xDI[0 +: 2*blind_n_rnd]),
        ._QxDO(_AsqscmulBxD)
    );
    
end

if (inverter_type == 2) begin
    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES))
    a_mul_e (
        .ClkxCI(ClkxCI),
        ._XxDI(_AxDP),
        ._YxDI(_AsqscmulBxD),
        ._ZxDI(_Zmul2xDI),
        ._QxDO(_AmulExD)
    );

    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES))
    b_mul_e (
        .ClkxCI(ClkxCI),
        ._XxDI(_BxDP),
        ._YxDI(_AsqscmulBxD),
        ._ZxDI(_Zmul3xDI),
        ._QxDO(_BmulExD)
    );
end else if (inverter_type == 1) begin
    real_dom_shared_mul_gf2_paired #(.PIPELINED(1),.SHARES(SHARES))
    mult_lsb (
        .ClkxCI(ClkxCI),
        ._YxDI(_AsqscmulBxD),
        ._X1xDI(_AxDP),
        ._X2xDI(_BxDP),
        ._Z1xDI(_Zmul2xDI),
        ._Z2xDI(_Zmul3xDI),
        ._BxDI(_Bmul1xDI[2*blind_n_rnd +: 2*blind_n_rnd]),
        ._Q1xDO(_AmulExD),
        ._Q2xDO(_BmulExD)
    );
end else if (inverter_type == 0) begin
    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    a_mul_e (
        .ClkxCI(ClkxCI),
        ._XxDI(_AxDP),
        ._YxDI(_AsqscmulBxD),
        ._ZxDI(_Zmul2xDI),
        ._BxDI(_Bmul1xDI[2*blind_n_rnd +: 2*blind_n_rnd]),
        ._QxDO(_AmulExD)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    b_mul_e (
        .ClkxCI(ClkxCI),
        ._XxDI(_BxDP),
        ._YxDI(_AsqscmulBxD),
        ._ZxDI(_Zmul3xDI),
        ._BxDI(_Bmul1xDI[4*blind_n_rnd +: 2*blind_n_rnd]),
        ._QxDO(_BmulExD)
    );
end

end


    
endmodule