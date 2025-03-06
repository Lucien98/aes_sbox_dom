`define RAND_OPT
module aes_sbox #(
    parameter PIPELINED = 1, // 1: yes
    // Only if pipelined variant is used!
    parameter EIGHT_STAGED = 0, // 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    // RstxBI,
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
`ifndef RAND_OPT
    _Binv3xDI,
`endif
    // Output Q = SBOX(X)
    _QxDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);


input ClkxCI;
// input RstxBI;
input [8*SHARES-1 : 0] _XxDI;
`ifndef PINI
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul1xDI; // for y1 * y0
`else
input [4*SHARES*(SHARES-1)-1 : 0] _Zmul1xDI; // for y1 * y0
`endif
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul2xDI; // for 0 * y1
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul3xDI; // for 0 * y0
input [SHARES*(SHARES-1)-1 : 0] _Zinv1xDI; // for inverter
input [SHARES*(SHARES-1)-1 : 0] _Zinv2xDI;
input [SHARES*(SHARES-1)-1 : 0] _Zinv3xDI;
input [2*blind_n_rnd-1 : 0] _Binv1xDI; // for inverter
input [2*blind_n_rnd-1 : 0] _Binv2xDI; // ...
`ifndef RAND_OPT
input [2*blind_n_rnd-1 : 0] _Binv3xDI; // ...
`endif
output [8*SHARES-1 : 0] _QxDO;

wire [7:0] XxDI [SHARES-1 : 0];
`ifndef FV
wire [7:0] QxDO [SHARES-1 : 0];
`else
reg [7:0] QxDO [SHARES-1 : 0];
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
wire [3:0] Y0xorY1xD [SHARES-1:0];
wire [3:0] Y0sqscmulY1xD [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y0sqscmulY1xD;
wire [3:0] InverterInxD [SHARES-1:0];
wire [4*SHARES-1 : 0] _InverterInxD;
wire [3:0] InverterOutxD [SHARES-1:0];
wire [4*SHARES-1 : 0] _InverterOutxD;
wire [3:0] InverseMSBxD [SHARES-1:0];
wire [4*SHARES-1 : 0] _InverseMSBxD;
wire [3:0] InverseLSBxD [SHARES-1:0];
wire [4*SHARES-1 : 0] _InverseLSBxD;
wire [7:0] InvUnmappedxD [SHARES-1:0];
wire [7:0] InvMappedxD [SHARES-1:0];
// Pipelining registers
reg [3:0] Y0_0xDP [SHARES-1:0];
reg [3:0] Y0_1xDP [SHARES-1:0];
reg [3:0] Y0_2xDP [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y0_2xDP;
reg [3:0] Y0_3xDP [SHARES-1:0];
reg [3:0] Y0_4xDP [SHARES-1:0];
reg [3:0] Y1_0xDP [SHARES-1:0];
wire [4*SHARES-1:0] _Y1_0xDP;
reg [3:0] Y1_1xDP [SHARES-1:0];
reg [3:0] Y1_2xDP [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y1_2xDP;
reg [3:0] Y1_3xDP [SHARES-1:0];
reg [3:0] Y1_4xDP [SHARES-1:0];
reg [7:0] mappedxDP [SHARES-1:0];
wire [3:0] InverterInxDP [SHARES-1:0];


for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        // Used in real_dom_shared_mul_gf4
        assign _Y1xD[i*4+j] = Y1xD[i][j];
        assign _Y0xD[i*4+j] = Y0xD[i][j];
        assign Y0sqscmulY1xD[i][j] = _Y0sqscmulY1xD[i*4+j];

        // Used in inverter
        assign _InverterInxD[i*4+j] = InverterInxD[i][j];
        assign InverterOutxD[i][j] = _InverterOutxD[i*4+j];

        // Used in shared_mul_gf4
        assign _Y0_2xDP[i*4+j] = Y0_2xDP[i][j];
        assign _Y1_0xDP[i*4+j] = Y1_0xDP[i][j];
        assign _Y1_2xDP[i*4+j] = Y1_2xDP[i][j];
        assign InverseMSBxD[i][j] = _InverseMSBxD[i*4+j];
        assign InverseLSBxD[i][j] = _InverseLSBxD[i*4+j];
    end
end



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
if (SHARES > 1 && PIPELINED == 1 && EIGHT_STAGED == 0) begin
    // Add pipelining stage after linear mapping at input,
    // between Stage 1 and 2
    integer k;
    always @(posedge ClkxCI /*or negedge RstxBI*/) begin
        // process pipeline_lin_map_p
        // if (~RstxBI) begin              // asynchronous reset (active low)
        //     for (k = 0; k < SHARES; k = k + 1)
        //     mappedxDP[k] <= 8'b0000;
        //     end //k
        // else begin  // rising clock edge
            for (k = 0; k < SHARES; k = k + 1)
            mappedxDP[k] <= mappedxD[k];
        // end //k
    end

    // Pipeline for Y0 and Y1
    // process pipeline_y0y1_p
    always @(posedge ClkxCI /*or negedge RstxBI*/) begin : proc_
        // if (~RstxBI) begin // asynchronous reset (active low)
        //     // per share
        //     for (k = 0; k < SHARES; k = k + 1) begin
        //         Y0_0xDP[k] = 4'b0000;
        //         Y0_1xDP[k] = 4'b0000;
        //         Y0_2xDP[k] = 4'b0000;
        //         Y1_0xDP[k] = 4'b0000;
        //         Y1_1xDP[k] = 4'b0000;
        //         Y1_2xDP[k] = 4'b0000;
        //     end
        // end
        // else begin // rising clock edge
            for (k = 0; k < SHARES; k = k + 1) begin
                
                Y0_2xDP[k] = Y0_1xDP[k];
                Y0_1xDP[k] = Y0_0xDP[k];
                Y0_0xDP[k] = Y0xD[k];
                Y1_2xDP[k] = Y1_1xDP[k];
                Y1_1xDP[k] = Y1_0xDP[k];
                Y1_0xDP[k] = Y1xD[k];
                // Y0xorY12xDP[k] = Y0xorY12xD[k];
            end
        // end
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


        // Inverter input
        // assign InverterInxD[i] = Y0mulY1xD[i] ^ Y0xorY12xDP[i];
        assign InverterInxD[i] = Y0sqscmulY1xD[i];

        // Inverse linear mapping
        assign InvUnmappedxD[i] = {InverseMSBxD[i], InverseLSBxD[i]};

        // Linear mapping at output
        lin_map #(.MATRIX_SEL(0))
        output_mapping (
            .DataInxDI(InvUnmappedxD[i]),
            .DataOutxDO(InvMappedxD[i])
        );
    end
`ifndef FV
    // Output
    for (i = 0; i < SHARES; i = i + 1) begin
        if (i > 0) begin
            assign QxDO[i] = InvMappedxD[i];
        end
        else begin // Add "b" only once
            assign QxDO[0] = InvMappedxD[0] ^ 8'b01100011;
        end
    end
`endif

    // Single instances:
    // Y1 sqsc Y0 + Y1 mul Y0 (GF 2^4)

`ifndef PINI
    shared_sqscmul_gf4 # (.PIPELINED(PIPELINED), .SHARES(SHARES))
    inst_shared_sqscmul_gf4 (
        .ClkxCI(ClkxCI),
        // .RstxBI(RstxBI),
        ._XxDI(_Y1xD),
        ._YxDI(_Y0xD),
        ._ZxDI(_Zmul1xDI),
        ._QxDO(_Y0sqscmulY1xD)
    );
`else
    shared_hpc3_sqscmul_gf4 # (.PIPELINED(PIPELINED), .SHARES(SHARES))
    inst_shared_sqscmul_gf4 (
        .ClkxCI(ClkxCI),
        // .RstxBI(RstxBI),
        ._XxDI(_Y1xD),
        ._XxDI_prev(_Y1_0xDP),
        ._YxDI(_Y0xD),
        ._ZxDI(_Zmul1xDI[0 +: 2*SHARES*(SHARES-1)]),
        ._RxDI(_Zmul1xDI[2*SHARES*(SHARES-1) +: 2*SHARES*(SHARES-1)]),
        ._QxDO(_Y0sqscmulY1xD)
    );
`endif 

    // Inverter in GF2^4
    inverter #(.VARIANT(1), .PIPELINED(PIPELINED), .EIGHT_STAGED_SBOX(0), .SHARES(SHARES))
    inverter_gf24 (
        .ClkxCI(ClkxCI),
        // .RstxBI(RstxBI),
        ._XxDI(_InverterInxD),
        ._Zmul1xDI(_Zinv1xDI),
        ._Zmul2xDI(_Zinv2xDI),
        ._Zmul3xDI(_Zinv3xDI),
        ._Bmul1xDI(_Binv1xDI),
        ._Bmul2xDI(_Binv2xDI),
`ifndef RAND_OPT
        ._Bmul3xDI(_Binv3xDI),
`endif
        ._QxDO(_InverterOutxD)
    );

    // Multiply Inv and Y0 (GF 2^4)
    shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_msb (
		.ClkxCI(ClkxCI),
		// .RstxBI(RstxBI),
		._XxDI(_InverterOutxD), 
		._YxDI(_Y0_2xDP), 
		._ZxDI(_Zmul2xDI), 
		._QxDO(_InverseMSBxD)
    );

    // Multiply Y1 and Inv (GF2^4)
    shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_lsb (
		.ClkxCI(ClkxCI),
		// .RstxBI(RstxBI),
		._XxDI(_InverterOutxD), 
		._YxDI(_Y1_2xDP), 
		._ZxDI(_Zmul3xDI), 
		._QxDO(_InverseLSBxD)
    );
end


    
endmodule