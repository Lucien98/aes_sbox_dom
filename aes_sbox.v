module aes_sbox #(
    parameter PIPELINED = 1, // 1: yes
    parameter SHARES = 2
) (
    ClkxCI,
    // Inputs: X and random data
    _XxDI,
    // Fresh masks
    RandomZ,
    RandomB,
    // Output Q = SBOX(X)
    _QxDO
);

`include "blind.vh"

localparam blind_n_rnd = _blind_nrnd(SHARES);
localparam n_random_z = SHARES*(SHARES-1);
localparam bcoeff = _bcoeff(SHARES);

input ClkxCI;
input [8*SHARES-1 : 0] _XxDI;

input [coeff*SHARES*(SHARES-1)-1 : 0] RandomZ;

input [bcoeff*blind_n_rnd-1:0] RandomB;

output [8*SHARES-1 : 0] _QxDO;

wire [(coeff-9)*SHARES*(SHARES-1)-1 : 0] _Zmul1xDI = RandomZ[9*n_random_z+:(coeff-9)*n_random_z]; // for y1 * y0
wire [2*SHARES*(SHARES-1)-1 : 0] _Zmul2xDI = RandomZ[7*n_random_z+:2*n_random_z]; // for 0 * y1
wire [2*SHARES*(SHARES-1)-1 : 0] _Zmul3xDI = RandomZ[5*n_random_z+:2*n_random_z]; // for 0 * y0



wire [SHARES*(SHARES-1)-1 : 0] _Zgf2_1xDI = RandomZ[0*n_random_z+:n_random_z]; // for mul_gf2
wire [SHARES*(SHARES-1)-1 : 0] _Zgf2_2xDI = RandomZ[1*n_random_z+:n_random_z];
wire [SHARES*(SHARES-1)-1 : 0] _Zgf2_3xDI = RandomZ[2*n_random_z+:n_random_z];
wire [SHARES*(SHARES-1)-1 : 0] _Zgf2_4xDI = RandomZ[3*n_random_z+:n_random_z];
wire [SHARES*(SHARES-1)-1 : 0] _Zgf2_5xDI = RandomZ[4*n_random_z+:n_random_z];


wire [4*blind_n_rnd-1 : 0] _Bgf4_1xDI = RandomB[0*blind_n_rnd +: 4*blind_n_rnd]; // for mul_gf4 in the second stage

wire [2*blind_n_rnd-1 : 0] _Bgf2_1xDI = RandomB[4*blind_n_rnd +: 2*blind_n_rnd]; // for mul_gf2

/*
`ifndef OPTO1O2
    wire [2*blind_n_rnd-1 : 0] _Bgf2_2xDI = RandomB[6*blind_n_rnd +: 2*blind_n_rnd];
    `define NOT_OPTO1O2
`else
    generate
        if (SHARES > 3) begin
            `define DEFBgf2_2
        end
    endgenerate
`endif
`ifdef DEFBgf2_2
wire [2*blind_n_rnd-1 : 0] _Bgf2_2xDI = RandomB[6*blind_n_rnd +: 2*blind_n_rnd];
`endif
*/
`ifndef OPTO1O2
    `ifndef RAND_OPT
        wire [4*blind_n_rnd-1 : 0] _Bgf4_2xDI = RandomB[14*blind_n_rnd +: 4*blind_n_rnd];
        wire [2*blind_n_rnd-1 : 0] _Bgf2_3xDI = RandomB[12*blind_n_rnd +: 2*blind_n_rnd];
        wire [2*blind_n_rnd-1 : 0] _Bgf2_4xDI = RandomB[10*blind_n_rnd +: 2*blind_n_rnd];
        wire [2*blind_n_rnd-1 : 0] _Bgf2_5xDI = RandomB[8*blind_n_rnd +: 2*blind_n_rnd];
        wire [2*blind_n_rnd-1 : 0] _Bgf2_2xDI = RandomB[6*blind_n_rnd +: 2*blind_n_rnd];
    `endif
    `undef NOT_OPTO1O2  // 避免宏污染
`endif


wire [7:0] XxDI [SHARES-1 : 0];
`ifdef FV
reg [7:0] QxDO [SHARES-1 : 0];
`else 
wire [7:0] QxDO [SHARES-1 : 0];
`endif
genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 8; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*8+j];
        assign _QxDO[i*8+j] = QxDO[i][j];
    end
end

// Shared signals
wire [7:0] mappedxD [SHARES-1:0];
wire [3:0] Y1xD [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y1xD;
wire [3:0] Y0xD [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y0xD;
wire [3:0] Y0sqscmulY1xD [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y0sqscmulY1xD;
wire [1:0] InverterOutxD [SHARES-1:0];
wire [2*SHARES-1 : 0] _InverterOutxD;
wire [3:0] InverseMSBxD [SHARES-1:0];
wire [4*SHARES-1 : 0] _InverseMSBxD;
wire [8*SHARES-1 : 0] _GF256InvxD;
wire [8*SHARES-1 : 0] _GF256InvxD_shbyte;
wire [3:0] InverseLSBxD [SHARES-1:0];
wire [4*SHARES-1 : 0] _InverseLSBxD;
wire [2*SHARES-1 : 0] _LSBLSB;
wire [2*SHARES-1 : 0] _LSBMSB;
wire [2*SHARES-1 : 0] _MSBLSB;
wire [2*SHARES-1 : 0] _MSBMSB;
wire [2*SHARES-1 : 0] _InvOutLSBLSB;
wire [2*SHARES-1 : 0] _InvOutLSBMSB;
wire [2*SHARES-1 : 0] _InvOutMSBLSB;
wire [2*SHARES-1 : 0] _InvOutMSBMSB;
wire [7:0] InvUnmappedxD [SHARES-1:0];
wire [7:0] InvMappedxD [SHARES-1:0];
// Pipelining registers
reg [3:0] Y0_0xDP [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y0_0xDP;
reg [3:0] Y1_0xDP [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y1_0xDP;
reg [7:0] mappedxDP [SHARES-1:0];

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        // Used in real_dom_shared_mul_gf4
        assign _Y1xD[i*4+j] = Y1xD[i][j];
        assign _Y0xD[i*4+j] = Y0xD[i][j];
        assign Y0sqscmulY1xD[i][j] = _Y0sqscmulY1xD[i*4+j];

        // Used in shared_mul_gf4
        assign _Y0_0xDP[i*4+j] = Y0_0xDP[i][j];
        assign _Y1_0xDP[i*4+j] = Y1_0xDP[i][j];

        assign InverseMSBxD[i][j] = _InverseMSBxD[i*4+j];
        assign InverseLSBxD[i][j] = _InverseLSBxD[i*4+j];
    end
end

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign InverterOutxD[i][j] = _InverterOutxD[i*2+j];
        assign _LSBLSB[i*2+j] = _InverseLSBxD[i*4+j];
        assign _LSBMSB[i*2+j] = _InverseLSBxD[i*4+j+2];

        assign _MSBLSB[i*2+j] = _InverseMSBxD[i*4+j];
        assign _MSBMSB[i*2+j] = _InverseMSBxD[i*4+j+2];
    end
    assign _GF256InvxD_shbyte[i*8+:8] = {_InvOutMSBMSB[i*2+:2], _InvOutMSBLSB[i*2+:2], _InvOutLSBMSB[i*2+:2], _InvOutLSBLSB[i*2+:2]};
end

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 8; j=j+1) begin
        // Used in inverter
        assign InvUnmappedxD[i][j] = _GF256InvxD_shbyte[i*8+j];
    end
end

wire [8*SHARES-1 : 0] _mappedxD;
wire [8*SHARES-1 : 0] _mappedxD_bit;
for (i = 0; i < SHARES; i=i+1) begin
    assign _mappedxD[8*i +: 8] = mappedxDP[i];
end

shblk2shbit #(.d(SHARES),.width(8))
switch_encoding_out (
    .shblk(_mappedxD),
    .shbit(_mappedxD_bit)
);

`ifndef FV
// Output
for (i = 0; i < SHARES; i = i + 1) begin
    if (i > 0) begin
        assign QxDO[i] = InvMappedxD[i];
    end
    else begin // Add "b" only once
        // assign QxDO[0] = InvMappedxD[0];// ^ 8'b01100011;
        assign QxDO[0] = InvMappedxD[0] ^ 8'b01100011;
    end
end
`endif

// General: Define aliases
for (i = 0; i < SHARES; i = i + 1) begin
`ifdef IAINREG
    assign Y1xD[i][3] = mappedxDP[i][7];
    assign Y1xD[i][2] = mappedxDP[i][6];
    assign Y1xD[i][1] = mappedxDP[i][5];
    assign Y1xD[i][0] = mappedxDP[i][4];
    assign Y0xD[i][3] = mappedxDP[i][3];
    assign Y0xD[i][2] = mappedxDP[i][2];
    assign Y0xD[i][1] = mappedxDP[i][1];
    assign Y0xD[i][0] = mappedxDP[i][0];
`else
    assign Y1xD[i][3] = mappedxD[i][7];
    assign Y1xD[i][2] = mappedxD[i][6];
    assign Y1xD[i][1] = mappedxD[i][5];
    assign Y1xD[i][0] = mappedxD[i][4];
    assign Y0xD[i][3] = mappedxD[i][3];
    assign Y0xD[i][2] = mappedxD[i][2];
    assign Y0xD[i][1] = mappedxD[i][1];
    assign Y0xD[i][0] = mappedxD[i][0];
`endif
end

// Masked and pipelined (5 staged) AES Sbox with variable order of security
if (SHARES > 1 && PIPELINED == 1) begin
    // Add pipelining stage after linear mapping at input,
    // between Stage 1 and 2
    integer k;
    always @(posedge ClkxCI) begin
        // process pipeline_lin_map_p
        for (k = 0; k < SHARES; k = k + 1)
            mappedxDP[k] <= mappedxD[k];
    end

    // Pipeline for Y0 and Y1
    // process pipeline_y0y1_p
    always @(posedge ClkxCI) begin : proc_
        for (k = 0; k < SHARES; k = k + 1) begin
            
            Y0_0xDP[k] = Y0xD[k];
            Y1_0xDP[k] = Y1xD[k];
        end
// store the output of S-box for formal verification
`ifdef FV
        // Output
        for (k = 0; k < SHARES; k = k + 1) begin
            if (k > 0) begin
                QxDO[k] = InvMappedxD[k];
            end
            else begin // Add "b" only once
                // assign QxDO[0] = InvMappedxD[0];// ^ 8'b01100011;
                QxDO[0] = InvMappedxD[0] ^ 8'b01100011;
            end
        end
`endif

    end

    // Generate instances per share...
    for (i = 0; i < SHARES; i = i + 1) begin
        // Liear mapping at input
`ifndef NOIA
        lin_map #(.MATRIX_SEL(1))
`else
        lin_map #(.MATRIX_SEL(2))
`endif
        input_mapping (
            .DataInxDI(XxDI[i]),
            .DataOutxDO(mappedxD[i])
        );

        // Linear mapping at output
        lin_map #(.MATRIX_SEL(0))
        output_mapping (
            .DataInxDI(InvUnmappedxD[i]),
            .DataOutxDO(InvMappedxD[i])
        );
    end

`ifndef OPTO1O2
    `ifndef PINI
        // 0: noia; 1:hpc3; 2: sni; 3:sni+pini, probably impossible in 1 cycle
        localparam stage1_type = 0;
    `else 
        localparam stage1_type = 1;
    `endif
`else 
    `ifndef PINI
        localparam stage1_type = SHARES <= 3 ? 2 : 0;
    `else 
        localparam stage1_type = SHARES <= 3 ? 3 : 1;
    `endif
`endif

if (stage1_type == 0) begin
    shared_sqscmul_gf4 # (.PIPELINED(PIPELINED), .SHARES(SHARES))
    inst_shared_sqscmul_gf4 (
        .ClkxCI(ClkxCI),
        ._YxDI(_Y1xD),
        ._XxDI(_Y0xD),
        ._ZxDI(_Zmul1xDI),
        ._QxDO(_Y0sqscmulY1xD)
    );
end
else if (stage1_type == 1) begin
    shared_hpc3_sqscmul_gf4 # (.PIPELINED(PIPELINED), .SHARES(SHARES))
    inst_shared_sqscmul_gf4 (
        .ClkxCI(ClkxCI),
        ._XxDI(_Y1xD),
        ._XxDI_prev(_Y1_0xDP),
        ._YxDI(_Y0xD),
        ._ZxDI(_Zmul1xDI[0 +: 2*SHARES*(SHARES-1)]),
        ._RxDI(_Zmul1xDI[2*SHARES*(SHARES-1) +: 2*SHARES*(SHARES-1)]),
        ._QxDO(_Y0sqscmulY1xD)
    );
end
else if(stage1_type == 2) begin
    shared_sqscmul_gf_sni # (.PIPELINED(PIPELINED), .SHARES(SHARES))
    inst_shared_sqscmul_gf4 (
        .ClkxCI(ClkxCI),
        ._YxDI(_Y1xD),
        ._XxDI(_Y0xD),
        ._ZxDI({_Zmul1xDI,_Bgf4_1xDI}),
        ._QxDO(_Y0sqscmulY1xD)
    );
end
else if(stage1_type == 3) begin
    initial begin
        $display("ERROR: OPTO1O2 and PINI can not be defined at the same time!");
        $finish;
    end
end

`ifndef OPTO1O2
    /*0: DOM-dep, 1: SNI*/
    `ifndef RAND_OPT
        localparam stage2gf2_type = 0;
    `else
        localparam stage2gf2_type = 2; 
    `endif
`else 
    `ifndef RAND_OPT
        localparam stage2gf2_type = SHARES <= 3 ? 1 : 0;
    `else
        localparam stage2gf2_type = SHARES <= 3 ? 1 : 2;
    `endif
`endif

    wire [2*SHARES-1 : 0] _A;
    wire [2*SHARES-1 : 0] _B;

    shared_gf4_to_shared_gf2 #(.SHARES(SHARES))
    switch_field (
        ._XxDI(_Y0sqscmulY1xD),
        ._A   (_A),
        ._B   (_B)
        );
    wire [3:0] BxDI [blind_n_rnd-1 : 0];
    wire [1:0] Bgf2_1 [SHARES-1 : 0];
    wire [2*blind_n_rnd-1 : 0] _Bgf2_1;
    for (i = 0; i < SHARES; i=i+1) begin
        assign Bgf2_1[i] = BxDI[i][1:0];
        for (j = 0; j < 4; j=j+1) begin
            assign BxDI[i][j] = _Bgf4_1xDI[i*4+j];
        end
        for (j = 0; j < 2; j=j+1) begin
            assign _Bgf2_1[i*2+j] = Bgf2_1[i][j];
        end
    end    


if (stage2gf2_type == 0) begin
    real_dom_shared_sqscmul_gf2 # (.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    a_sqscmul_b
    (
        .ClkxCI(ClkxCI),
        ._XxDI(_A),
        ._YxDI(_B),
        ._ZxDI(_Zgf2_1xDI),
        ._BxDI(_Bgf2_1),
        ._QxDO(_InverterOutxD)
    );
end
else if (stage2gf2_type == 1) begin
    shared_sqscmul_gf_sni # (.PIPELINED(PIPELINED), .SHARES(SHARES), .N(2))
    a_sqscmul_b
    (
        .ClkxCI(ClkxCI),
        ._XxDI(_A),
        ._YxDI(_B),
        ._ZxDI({_Zgf2_1xDI,_Bgf2_1xDI}),
        ._QxDO(_InverterOutxD)
    );
end

`ifndef OPTO1O2
    `ifndef RAND_OPT
        /*
        0: 2 (or 4) independent dom-dep; 
        1: 2 (or 4) dom-dep shares the same blinded Y; 
        2: 2 (or 4) dom-indep; 
        */
        localparam stage2gf4_type = 0;
    `else 
        localparam stage2gf4_type = 1;
    `endif
`else 
    `ifndef RAND_OPT
        localparam stage2gf4_type = SHARES <= 3 ? 2 : 0;
    `else 
        localparam stage2gf4_type = SHARES <= 3 ? 2 : 1;
    `endif
`endif


if (stage2gf4_type == 0) begin
    // Multiply Inv and Y0 (GF 2^4)
    real_dom_shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_msb (
		.ClkxCI(ClkxCI),
		._YxDI(_Y0sqscmulY1xD),
		._XxDI(_Y0_0xDP),
		._ZxDI(_Zmul2xDI), 
        ._BxDI(_Bgf4_1xDI),
		._QxDO(_InverseMSBxD)
    );

    // Multiply Y1 and Inv (GF2^4)
    real_dom_shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_lsb (
		.ClkxCI(ClkxCI),
		._YxDI(_Y0sqscmulY1xD),
		._XxDI(_Y1_0xDP),
		._ZxDI(_Zmul3xDI), 
        ._BxDI(_Bgf4_2xDI),
		._QxDO(_InverseLSBxD)
    );
    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_0 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_LSBLSB),
        ._ZxDI(_Zgf2_2xDI),
        ._BxDI(_Bgf2_2xDI),
        ._QxDO(_InvOutLSBLSB)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_1 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_LSBMSB),
        ._ZxDI(_Zgf2_3xDI),
        ._BxDI(_Bgf2_3xDI),
        ._QxDO(_InvOutLSBMSB)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_2 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_MSBLSB),
        ._ZxDI(_Zgf2_4xDI),
        ._BxDI(_Bgf2_4xDI),
        ._QxDO(_InvOutMSBLSB)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_3 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_MSBMSB),
        ._ZxDI(_Zgf2_5xDI),
        ._BxDI(_Bgf2_5xDI),
        ._QxDO(_InvOutMSBMSB)
    );

end
else if (stage2gf4_type == 1) begin
    /* 
    real_dom_shared_mul_gf4_paired #(.PIPELINED(1),.SHARES(SHARES))
    mult_lsb (
        .ClkxCI(ClkxCI),
        ._YxDI(_Y0sqscmulY1xD),
        ._X1xDI(_Y0_0xDP),
        ._X2xDI(_Y1_0xDP),
        ._Z1xDI(_Zmul2xDI), 
        ._Z2xDI(_Zmul3xDI), 
        ._BxDI(_Bgf4_1xDI),
        ._Q2xDO(_InverseLSBxD),
        ._Q1xDO(_InverseMSBxD)
    );
    */
    
    real_dom_shared_stage2 #(.PIPELINED(1),.SHARES(SHARES))
    mult_stage2 (
        .ClkxCI(ClkxCI),
        ._YxDI(_Y0sqscmulY1xD),
        ._X1xDI(_Y0_0xDP),
        ._X2xDI(_Y1_0xDP),
        ._Z1xDI(_Zmul2xDI), 
        ._Z2xDI(_Zmul3xDI), 
        ._ZxDI(_Zgf2_1xDI),
        ._BxDI(_Bgf4_1xDI),
        ._Q2xDO(_InverseLSBxD),
        ._Q1xDO(_InverseMSBxD),
        ._QxDO(_InverterOutxD)
    );

    real_dom_shared_mul_gf2_quadruple #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_quad (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._X1xDI(_LSBLSB),
        ._X2xDI(_LSBMSB),
        ._X3xDI(_MSBLSB),
        ._X4xDI(_MSBMSB),
        ._Z1xDI(_Zgf2_2xDI),
        ._Z2xDI(_Zgf2_3xDI),
        ._Z3xDI(_Zgf2_4xDI),
        ._Z4xDI(_Zgf2_5xDI),
        ._BxDI(_Bgf2_1xDI),
        ._Q1xDO(_InvOutLSBLSB),
        ._Q2xDO(_InvOutLSBMSB),
        ._Q3xDO(_InvOutMSBLSB),
        ._Q4xDO(_InvOutMSBMSB)
    );
end
else if (stage2gf4_type == 2) begin
    // Multiply Inv and Y0 (GF 2^4)
    shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_msb (
        .ClkxCI(ClkxCI),
        ._YxDI(_Y0sqscmulY1xD),
        ._XxDI(_Y0_0xDP),
        ._ZxDI(_Zmul2xDI), 
        ._QxDO(_InverseMSBxD)
    );

    // Multiply Y1 and Inv (GF2^4)
    shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_lsb (
        .ClkxCI(ClkxCI),
        ._YxDI(_Y0sqscmulY1xD),
        ._XxDI(_Y1_0xDP),
        ._ZxDI(_Zmul3xDI), 
        ._QxDO(_InverseLSBxD)
    );
    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES))
    theta_mul_0 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_LSBLSB),
        ._ZxDI(_Zgf2_2xDI),
        ._QxDO(_InvOutLSBLSB)
    );

    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES))
    theta_mul_1 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_LSBMSB),
        ._ZxDI(_Zgf2_3xDI),
        ._QxDO(_InvOutLSBMSB)
    );

    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES))
    theta_mul_2 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_MSBLSB),
        ._ZxDI(_Zgf2_4xDI),
        ._QxDO(_InvOutMSBLSB)
    );

    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES))
    theta_mul_3 (
        .ClkxCI(ClkxCI),
        ._YxDI(_InverterOutxD),
        ._XxDI(_MSBMSB),
        ._ZxDI(_Zgf2_5xDI),
        ._QxDO(_InvOutMSBMSB)
    );

end

end


    
endmodule