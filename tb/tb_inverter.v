`timescale 1ns/1ps
module tb_inverter ();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam N = 2;
    localparam VARIANT = 1;
    localparam PIPELINED = 1;
    localparam EIGHT_STAGED_SBOX = 0;
    localparam SHARES = 2; // change it to test different cases

    // General signals
	reg ClkxCI;
	// reg RstxBI;

    reg [3:0] XxDI [SHARES-1 : 0];
    wire [3:0] QxDO [SHARES-1 : 0];

    wire [4*SHARES-1 : 0] _XxDI;
    wire [SHARES*(SHARES-1)-1 : 0] _Zmul1xDI;
    wire [SHARES*(SHARES-1)-1 : 0] _Zmul2xDI;
    wire [SHARES*(SHARES-1)-1 : 0] _Zmul3xDI;
    wire [2*SHARES-1 : 0] _Bmul1xDI;
    wire [2*SHARES-1 : 0] _Bmul2xDI;
    wire [2*SHARES-1 : 0] _Bmul3xDI;
    wire [4*SHARES-1 : 0] _QxDO;

    for (genvar i = 0; i < SHARES; i=i+1) begin
        for (genvar j = 0; j < 4; j=j+1) begin
            assign _XxDI[i*4+j] = XxDI[i][j];
            assign QxDO[i][j] = _QxDO[i*4+j];
        end
    end

    reg [3:0] X;
    reg [3:0] Q;

    for (genvar i = 0; i < SHARES*(SHARES-1); i=i+1) begin
        assign _Zmul1xDI[i] = $random;
        assign _Zmul2xDI[i] = $random;
        assign _Zmul3xDI[i] = $random;
        
    end

    for (genvar i = 0; i < 2*SHARES; i=i+1) begin
        assign _Bmul1xDI[i] = $random;
        assign _Bmul2xDI[i] = $random;
        assign _Bmul3xDI[i] = $random;
        
    end

    inverter #(.VARIANT(VARIANT), .PIPELINED(PIPELINED), .EIGHT_STAGED_SBOX(EIGHT_STAGED_SBOX), .SHARES(SHARES))
    inst_inverter (
        .ClkxCI(ClkxCI),
        // .RstxBI(RstxBI),
        ._XxDI(_XxDI),
        ._Zmul1xDI(_Zmul1xDI),
        ._Zmul2xDI(_Zmul2xDI),
        ._Zmul3xDI(_Zmul3xDI),
        ._Bmul1xDI(_Bmul1xDI),
        ._Bmul2xDI(_Bmul2xDI),
        ._Bmul3xDI(_Bmul3xDI),
        ._QxDO(_QxDO)
    );

    // Create clock
	always@(*) #Td ClkxCI<=~ClkxCI;

	initial begin
        ClkxCI = 0;
		// RstxBI = 0;
        for (integer k = 0; k < SHARES; k=k+1) begin
			XxDI[k] <= 0;
		end
		#T;
		// RstxBI = 1;
		#T;
        
        for (integer k = 0; k < 100; k = k + 1) begin 
            X = 4'b0000;
            Q = 4'b0000;
            for (integer i = 0; i < SHARES; i = i + 1) begin
                XxDI[i] = $random;
                X = X ^ XxDI[i];
                Q = Q ^ QxDO[i];
            end
            #T;
        end
        

    end


endmodule