`timescale 1ns/1ps
module tb_aes_sbox ();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam N = 2;
    localparam PIPELINED = 1;
    localparam EIGHT_STAGED = 0;
    localparam SHARES = 2; // change it to test different cases

    // General signals
	reg ClkxCI;
	reg RstxBI;
    `include "blind.vh"
    localparam blind_n_rnd = _blind_nrnd(SHARES);
    reg [11*SHARES*(SHARES-1)-1 : 0] RandomZ;
    reg [2*9*blind_n_rnd-1:0] RandomB;

    wire [8*SHARES-1 : 0] _XxDI;
    // reg [2*SHARES*(SHARES-1)-1 : 0] _Zmul1xDI; // for y1 * y0
    // reg [2*SHARES*(SHARES-1)-1 : 0] _Zmul2xDI; // for 0 * y1
    // reg [2*SHARES*(SHARES-1)-1 : 0] _Zmul3xDI; // for 0 * y0
    // reg [SHARES*(SHARES-1)-1 : 0] _Zinv1xDI; // for inverter
    // reg [SHARES*(SHARES-1)-1 : 0] _Zinv2xDI;
    // reg [SHARES*(SHARES-1)-1 : 0] _Zinv3xDI;
    // // reg [4*blind_n_rnd-1 : 0] _Bmul1xDI; // for y1 * y0
    // reg [2*blind_n_rnd-1 : 0] _Binv1xDI; // for inverter
    // reg [2*blind_n_rnd-1 : 0] _Binv2xDI; // ...
    // reg [2*blind_n_rnd-1 : 0] _Binv3xDI; // ...
    wire [8*SHARES-1 : 0] _QxDO;

    reg [7:0] XxDI [SHARES-1 : 0];
    wire [7:0] QxDO [SHARES-1 : 0];

    reg [7:0] X;
    reg [7:0] Q;

    for (genvar i = 0; i < SHARES; i=i+1) begin
        for (genvar j = 0; j < 8; j=j+1) begin
            assign _XxDI[i*8+j] = XxDI[i][j];
            assign QxDO[i][j] = _QxDO[i*8+j];
        end
    end

    aes_sbox #(.PIPELINED(PIPELINED), .EIGHT_STAGED(EIGHT_STAGED), .SHARES(SHARES))
    inst_aes_sbox (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_XxDI),
        .RandomZ(RandomZ),
        .RandomB(RandomB),
        // ._Zmul1xDI(_Zmul1xDI),
        // ._Zmul2xDI(_Zmul2xDI),
        // ._Zmul3xDI(_Zmul3xDI),
        // ._Zinv1xDI(_Zinv1xDI),
        // ._Zinv2xDI(_Zinv2xDI),
        // ._Zinv3xDI(_Zinv3xDI),
        // ._Binv1xDI(_Binv1xDI),
        // ._Binv2xDI(_Binv2xDI),
        // ._Binv3xDI(_Binv3xDI),
        ._QxDO(_QxDO)
    );

    // Create clock
	always@(*) #Td ClkxCI<=~ClkxCI;

	initial begin
        ClkxCI = 0;
		RstxBI = 0;
        #T;
        RstxBI = 1;
        for (integer k = 0; k < SHARES; k=k+1) begin
			XxDI[k] = 0;
            // _Zmul1xDI = $random;
            // _Zmul2xDI = $random;
            // _Zmul3xDI = $random;
            // _Zinv1xDI = $random;
            // _Zinv2xDI = $random;
            // _Zinv3xDI = $random;
            // // _Bmul1xDI = $random;
            // _Binv1xDI = $random;
            // _Binv2xDI = $random;
            // _Binv3xDI = $random;
            RandomB = $random;
            RandomZ = $random;
		end
		#T;
        
        for (integer i = 0; i < 256; i = i + 1) begin
            XxDI[1] = i;
            for (integer j = 0; j < 256; j = j + 1) begin
                XxDI[0] = j;
                X = 4'b0000;
                Q = 4'b0000;
                RandomB = $random;
                RandomZ = $random;
                // _Zmul1xDI = $random;
                // _Zmul2xDI = $random;
                // _Zmul3xDI = $random;
                // _Zinv1xDI = $random;
                // _Zinv2xDI = $random;
                // _Zinv3xDI = $random;
                // _Binv1xDI = $random;
                // _Binv2xDI = $random;
                // _Binv3xDI = $random;
                for (integer k = 0; k < SHARES; k = k + 1) begin
                    X = X ^ XxDI[k];
                    Q = Q ^ QxDO[k];
                end
                #T;
            end
        end
        #T;
        
    end


endmodule