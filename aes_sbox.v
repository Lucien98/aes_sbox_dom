module aes_sbox #(
    parameter PIPELINED = 1, // 1: yes
    // Only if pipelined variant is used!
    parameter EIGHT_STAGED = 0, // 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    RstxBI,
    // Inputs: X and random data
    _XxDI,
    // Fresh masks
    _Zmul1xDI,
    _Zmul2xDI,
    _Zmul3xDI,
    _Zinv1xDI,
    _Zinv2xDI,
    _Zinv3xDI,
    // Blinding values for Inverter (for 5 stage Sbox only)
    _Binv1xDI,
    _Binv2xDI,
    _Binv3xDI,
    // Output Q = SBOX(X)
    _QxDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);


input ClkxCI;
input RstxBI;
input [8*SHARES-1 : 0] _XxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul1xDI; // for y1 * y0
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul2xDI; // for 0 * y1
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul3xDI; // for 0 * y0
input [SHARES*(SHARES-1)-1 : 0] _Zinv1xDI; // for inverter
input [SHARES*(SHARES-1)-1 : 0] _Zinv2xDI;
input [SHARES*(SHARES-1)-1 : 0] _Zinv3xDI;
input [2*blind_n_rnd-1 : 0] _Binv1xDI; // for inverter
input [2*blind_n_rnd-1 : 0] _Binv2xDI; // ...
input [2*blind_n_rnd-1 : 0] _Binv3xDI; // ...
output [8*SHARES-1 : 0] _QxDO;

wire [7:0] XxDI [SHARES-1 : 0];
wire [7:0] QxDO [SHARES-1 : 0];

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
wire [3:0] Y0xorY1xD [SHARES-1:0];
wire [3:0] Y0sqscmulY1xD [SHARES-1:0];
wire [3:0] Y0sqscmulY1;
assign Y0sqscmulY1 = Y0sqscmulY1xD[0] ^ Y0sqscmulY1xD[1];
wire [4*SHARES-1 : 0] _Y0sqscmulY1xD;
wire [3:0] InverterInxD [SHARES-1:0];
wire [4*SHARES-1 : 0] _InverterInxD;
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
wire [3:0] InverterInxDP [SHARES-1:0];

wire[1:0] MSBMSB;

wire[1:0] MSBLSB;

wire[1:0] LSBMSB;

wire[1:0] LSBLSB;

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        // Used in real_dom_shared_mul_gf4
        assign _Y1xD[i*4+j] = Y1xD[i][j];
        assign _Y0xD[i*4+j] = Y0xD[i][j];
        assign Y0sqscmulY1xD[i][j] = _Y0sqscmulY1xD[i*4+j];

        // Used in shared_mul_gf4
        assign _Y0_0xDP[i*4+j] = Y0_0xDP[i][j];
        assign _Y1_0xDP[i*4+j] = Y1_0xDP[i][j];
        // Used in inverter
        assign _InverterInxD[i*4+j] = InverterInxD[i][j];

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
    assign _GF256InvxD_shbyte[i*8+:8] = {_InvOutMSBMSB[i*SHARES+:2], _InvOutMSBLSB[i*SHARES+:2], _InvOutLSBMSB[i*SHARES+:2], _InvOutLSBLSB[i*SHARES+:2]};
end

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 8; j=j+1) begin
        // Used in inverter
        assign InvUnmappedxD[i][j] = _GF256InvxD_shbyte[i*8+j];
    end
end


// General: Define aliases
for (i = 0; i < SHARES; i = i + 1) begin
    if (PIPELINED == 1 && EIGHT_STAGED == 0) begin
        assign Y1xD[i][3] = mappedxDP[i][7];
        assign Y1xD[i][2] = mappedxDP[i][6];
        assign Y1xD[i][1] = mappedxDP[i][5];
        assign Y1xD[i][0] = mappedxDP[i][4];
        assign Y0xD[i][3] = mappedxDP[i][3];
        assign Y0xD[i][2] = mappedxDP[i][2];
        assign Y0xD[i][1] = mappedxDP[i][1];
        assign Y0xD[i][0] = mappedxDP[i][0];
    end
    else begin
        assign Y1xD[i][3] = mappedxD[i][7];
        assign Y1xD[i][2] = mappedxD[i][6];
        assign Y1xD[i][1] = mappedxD[i][5];
        assign Y1xD[i][0] = mappedxD[i][4];
        assign Y0xD[i][3] = mappedxD[i][3];
        assign Y0xD[i][2] = mappedxD[i][2];
        assign Y0xD[i][1] = mappedxD[i][1];
        assign Y0xD[i][0] = mappedxD[i][0];
    end
end

// Masked and pipelined (5 staged) AES Sbox with variable order of security
if (SHARES > 1 && PIPELINED == 1 && EIGHT_STAGED == 0) begin
    // Add pipelining stage after linear mapping at input,
    // between Stage 1 and 2
    integer k;
    always @(posedge ClkxCI or negedge RstxBI) begin
        // process pipeline_lin_map_p
        if (~RstxBI) begin              // asynchronous reset (active low)
            for (k = 0; k < SHARES; k = k + 1)
            mappedxDP[k] <= 8'b0000;
            end //k
        else begin  // rising clock edge
            for (k = 0; k < SHARES; k = k + 1)
            mappedxDP[k] <= mappedxD[k];
            end //k
    end

    // Pipeline for Y0 and Y1
    // process pipeline_y0y1_p
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            // per share
            for (k = 0; k < SHARES; k = k + 1) begin
                Y0_0xDP[k] = 4'b0000;
                Y1_0xDP[k] = 4'b0000;
            end
        end
        else begin // rising clock edge
            for (k = 0; k < SHARES; k = k + 1) begin
                
                Y0_0xDP[k] = Y0xD[k];
                Y1_0xDP[k] = Y1xD[k];
            end
        end
    end

    // Generate instances per share...
    for (i = 0; i < SHARES; i = i + 1) begin
        // Liear mapping at input
        lin_map #(.MATRIX_SEL(1))
        input_mapping (
            .DataInxDI(XxDI[i]),
            .DataOutxDO(mappedxD[i])
        );

        // Inverter input
        assign InverterInxD[i] = Y0sqscmulY1xD[i];

        // Linear mapping at output
        lin_map #(.MATRIX_SEL(0))
        output_mapping (
            .DataInxDI(InvUnmappedxD[i]),
            .DataOutxDO(InvMappedxD[i])
        );
    end

    // Output
    for (i = 0; i < SHARES; i = i + 1) begin
        if (i > 0) begin
            assign QxDO[i] = InvMappedxD[i];
        end
        else begin // Add "b" only once
            assign QxDO[0] = InvMappedxD[0];// ^ 8'b01100011;
            // assign QxDO[0] = InvMappedxD[0] ^ 8'b01100011;
        end
    end

    // Single instances:
    // Y1 sqsc Y0 + Y1 mul Y0 (GF 2^4)
    shared_sqscmul_gf4 # (.PIPELINED(PIPELINED), .SHARES(SHARES))
    inst_shared_sqscmul_gf4 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_Y1xD),
        ._YxDI(_Y0xD),
        ._ZxDI(_Zmul1xDI),
        ._QxDO(_Y0sqscmulY1xD)
    );

    // Inverter in GF2^4
    real_dom_sqscmul_gf2_wraper #(.VARIANT(1), .PIPELINED(PIPELINED), .EIGHT_STAGED_SBOX(0), .SHARES(SHARES))
    inverter_gf24 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_Y0sqscmulY1xD /*_InverterInxD*/),
        ._Zmul1xDI(_Zinv1xDI),
        ._Zmul2xDI(_Zinv2xDI),
        ._Zmul3xDI(_Zinv3xDI),
        ._Bmul1xDI(_Binv1xDI),
        ._Bmul2xDI(_Binv2xDI),
        ._Bmul3xDI(_Binv3xDI),
        ._QxDO(_InverterOutxD)
    );

    // Multiply Inv and Y0 (GF 2^4)
    shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_msb (
		.ClkxCI(ClkxCI),
		.RstxBI(RstxBI),
		._XxDI(_Y0sqscmulY1xD), 
		._YxDI(_Y0_0xDP), 
		._ZxDI(_Zmul2xDI), 
		._QxDO(_InverseMSBxD)
    );

    assign MSBMSB = _InverseMSBxD[7:6] ^ _InverseMSBxD[3:2];

    assign MSBLSB = _InverseMSBxD[5:4] ^ _InverseMSBxD[1:0];

    // Multiply Y1 and Inv (GF2^4)
    shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_lsb (
		.ClkxCI(ClkxCI),
		.RstxBI(RstxBI),
		._XxDI(_Y0sqscmulY1xD), 
		._YxDI(_Y1_0xDP), 
		._ZxDI(_Zmul3xDI), 
		._QxDO(_InverseLSBxD)
    );

    assign LSBMSB = _InverseLSBxD[7:6] ^ _InverseLSBxD[3:2];

    assign LSBLSB = _InverseLSBxD[5:4] ^ _InverseLSBxD[1:0];

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_0 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_InverterOutxD),
        ._YxDI(_LSBLSB),
        ._ZxDI(0),
        ._BxDI(0),
        ._QxDO(_InvOutLSBLSB)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_1 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_InverterOutxD),
        ._YxDI(_LSBMSB),
        ._ZxDI(0),
        ._BxDI(0),
        ._QxDO(_InvOutLSBMSB)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_2 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_InverterOutxD),
        ._YxDI(_MSBLSB),
        ._ZxDI(0),
        ._BxDI(0),
        ._QxDO(_InvOutMSBLSB)
    );

    real_dom_shared_mul_gf2 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    theta_mul_3 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_InverterOutxD),
        ._YxDI(_MSBMSB),
        ._ZxDI(0),
        ._BxDI(0),
        ._QxDO(_InvOutMSBMSB)
    );



end


    
endmodule