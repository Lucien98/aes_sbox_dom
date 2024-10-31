module aes_box #(
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
    // Blinding values for Y0*Y1 and Inverter (for 5 stage Sbox only)
    _Bmul1xDI,
    _Binv1xDI,
    _Binv2xDI,
    _Binv3xDI,
    // Output Q = SBOX(X)
    _QxDO
);
input ClkxCI;
input RstxBI;
input [8*SHARES-1 : 0] _XxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul1xDI; // for y1 * y0
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul2xDI; // for 0 * y1
input [2*SHARES*(SHARES-1)-1 : 0] _Zmul3xDI; // for 0 * y0
input [SHARES*(SHARES-1)-1 : 0] _Zinv1xDI; // for inverter
input [SHARES*(SHARES-1)-1 : 0] _Zinv2xDI;
input [SHARES*(SHARES-1)-1 : 0] _Zinv3xDI;
input [4*SHARES-1 : 0] _Bmul1xDI; // for y1 * y0
input [2*SHARES-1 : 0] _Binv1xDI; // for inverter
input [2*SHARES-1 : 0] _Binv2xDI; // ...
input [2*SHARES-1 : 0] _Binv3xDI; // ...
output [8*SHARES-1 : 0] _QxDO;

wire [7:0] XxDI [SHARES-1 : 0];
wire [7:0] QxDO [SHARES-1 : 0];

for (genvar i = 0; i < SHARES; i=i+1) begin
    for (genvar j = 0; j < 8; j=j+1) begin
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
wire [3:0] Y0xorY12xD [SHARES-1:0];
wire [3:0] Y0mulY1xD [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y0mulY1xD;
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
reg [3:0] Y1_1xDP [SHARES-1:0];
reg [3:0] Y1_2xDP [SHARES-1:0];
wire [4*SHARES-1 : 0] _Y1_2xDP;
reg [3:0] Y1_3xDP [SHARES-1:0];
reg [3:0] Y1_4xDP [SHARES-1:0];
reg [3:0] Y0xorY12xDP [SHARES-1:0];
reg [7:0] mappedxDP [SHARES-1:0];
wire [3:0] InverterInxDP [SHARES-1:0];



for (genvar i = 0; i < SHARES; i=i+1) begin
    for (genvar j = 0; j < 4; j=j+1) begin
        // Used in real_dom_shared_mul_gf4
        assign _Y1xD[i*4+j] = Y1xD[i][j];
        assign _Y0xD[i*4+j] = Y0xD[i][j];
        assign Y0mulY1xD[i][j] = _Y0mulY1xD[i*4+j];

        // Used in inverter
        assign _InverterInxD[i*4+j] = InverterInxD[i][j];
        assign InverterOutxD[i][j] = _InverterOutxD[i*4+j];

        // Used in shared_mul_gf4
        assign _Y0_2xDP[i*4+j] = Y0_2xDP[i][j];
        assign _Y1_2xDP[i*4+j] = Y1_2xDP[i][j];
        assign InverseMSBxD[i][j] = _InverseMSBxD[i*4+j];
        assign InverseLSBxD[i][j] = _InverseLSBxD[i*4+j];
    end
end


// General: Define aliases
for (genvar i = 0; i < SHARES; i = i + 1) begin
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
    always @(posedge ClkxCI or negedge RstxBI) begin
    begin  // process pipeline_lin_map_p
      if (~RstxBI) begin              // asynchronous reset (active low)
        for (integer i = 0; i < SHARES; i = i + 1)
          mappedxDP[i]     <= 8'b0000;
        end //i
      else begin  // rising clock edge
        for (integer i = 0; i < SHARES; i = i + 1)
          mappedxDP[i]     <= mappedxD[i];
        end //i
      end
    end
    
    // Pipeline for Y0 and Y1
    // process pipeline_y0y1_p
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            // per share
            for (integer i = 0; i < SHARES; i = i + 1) begin
                Y0_0xDP[i] = 4'b0000;
                Y0_1xDP[i] = 4'b0000;
                Y0_2xDP[i] = 4'b0000;
                Y1_0xDP[i] = 4'b0000;
                Y1_1xDP[i] = 4'b0000;
                Y1_2xDP[i] = 4'b0000;
            end
        end
        else begin // rising clock edge
            for (integer i = 0; i < SHARES; i = i + 1) begin
                
                Y0_2xDP[i] = Y0_1xDP[i];
                Y0_1xDP[i] = Y0_0xDP[i];
                Y0_0xDP[i] = Y0xD[i];
                Y1_2xDP[i] = Y1_1xDP[i];
                Y1_1xDP[i] = Y1_0xDP[i];
                Y1_0xDP[i] = Y1xD[i];
                Y0xorY12xDP[i] = Y0xorY12xD[i];
            end
        end
    end

    // Generate instances per share...
    for (genvar i = 0; i < SHARES; i = i + 1) begin
        // Liear mapping at input
        lin_map #(.MATRIX_SEL(1))
        input_mapping (
            .DataInxDI(XxDI[i]),
            .DataOutxDO(mappedxD[i])
        );

        // Input is split up in Y1 and Y0
        assign Y0xorY1xD[i] = Y1xD[i] ^ Y0xD[i];

        // Square sclaer
        square_scaler
        square_scaler_gf24 (
            .DataInxDI(Y0xorY1xD[i]),
            .DataOutxDO(Y0xorY12xD[i])
        );

        // Inverter input
        assign InverterInxD[i] = Y0mulY1xD[i] ^ Y0xorY12xDP[i];

        // Inverse linear mapping
        assign InvUnmappedxD[i] = {InverseMSBxD[i], InverseLSBxD[i]};

        // Linear mapping at output
        lin_map #(.MATRIX_SEL(0))
        output_mapping (
            .DataInxDI(InvUnmappedxD[i]),
            .DataOutxDO(InvMappedxD[i])
        );
    end

    // Output
    for (genvar i = 0; i < SHARES; i = i + 1) begin
        if (i > 0) begin
            assign QxDO[i] = InvMappedxD[i];
        end
        else begin // Add "b" only once
            assign QxDO[0] = InvMappedxD[0] ^ 8'b01100011;
        end
    end

    // Single instances:
    // Multiply Y1 and Y0 (GF 2^4)
    real_dom_shared_mul_gf4 #(.PIPELINED(PIPELINED), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES))
    inst_real_dom_shared_mul_gf4 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_Y1xD),
        ._YxDI(_Y0xD),
        ._ZxDI(_Zmul1xDI),
        ._BxDI(_Bmul1xDI),
        ._QxDO(_Y0mulY1xD)
    );

    // Inverter in GF2^4
    inverter #(.VARIANT(1), .PIPELINED(PIPELINED), .EIGHT_STAGED_SBOX(0), .SHARES(SHARES))
    inverter_gf24 (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_InverterInxD),
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
		._XxDI(_InverterOutxD), 
		._YxDI(_Y0_2xDP), 
		._ZxDI(_Zmul2xDI), 
		._QxDO(_InverseMSBxD)
    );

    // Multiply Y1 and Inv (GF2^4)
    shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES))
    mult_lsb (
		.ClkxCI(ClkxCI),
		.RstxBI(RstxBI),
		._XxDI(_InverterOutxD), 
		._YxDI(_Y1_2xDP), 
		._ZxDI(_Zmul3xDI), 
		._QxDO(_InverseLSBxD)
    );
end


    
endmodule