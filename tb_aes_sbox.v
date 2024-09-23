`timescale 1ns/1ps
module tb_aes_box ();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam N = 2;
    localparam PIPELINED = 1;
    localparam EIGHT_STAGED = 0;
    localparam SHARES = 2; // change it to test different cases

    // General signals
	reg ClkxCI;
	reg RstxBI;

    wire [8*SHARES-1 : 0] _XxDI;
    wire [2*SHARES*(SHARES-1)-1 : 0] _Zmul1xDI; // for y1 * y0
    wire [2*SHARES*(SHARES-1)-1 : 0] _Zmul2xDI; // for 0 * y1
    wire [2*SHARES*(SHARES-1)-1 : 0] _Zmul3xDI; // for 0 * y0
    wire [SHARES*(SHARES-1)-1 : 0] _Zinv1xDI; // for inverter
    wire [SHARES*(SHARES-1)-1 : 0] _Zinv2xDI;
    wire [SHARES*(SHARES-1)-1 : 0] _Zinv3xDI;
    wire [4*SHARES-1 : 0] _Bmul1xDI; // for y1 * y0
    wire [2*SHARES-1 : 0] _Binv1xDI; // for inverter
    wire [2*SHARES-1 : 0] _Binv2xDI; // ...
    wire [2*SHARES-1 : 0] _Binv3xDI; // ...
    wire [8*SHARES-1 : 0] _QxDO;

    reg [7:0] XxDI [SHARES-1 : 0];
    wire [7:0] QxDO [SHARES-1 : 0];

    for (genvar i = 0; i < SHARES; i=i+1) begin
        for (genvar j = 0; j < 8; j=j+1) begin
            assign _XxDI[i*8+j] = XxDI[i][j];
            assign QxDO[i][j] = _QxDO[i*8+j];
        end
    end

    for (genvar i = 0; i < 2*SHARES*(SHARES-1); i=i+1) begin
        assign _Zmul1xDI[i] = 0;
        assign _Zmul2xDI[i] = 0;
        assign _Zmul3xDI[i] = 0;
    end

    for (genvar i = 0; i < SHARES*(SHARES-1); i=i+1) begin
        assign _Zinv1xDI[i] = 0;
        assign _Zinv2xDI[i] = 0;
        assign _Zinv3xDI[i] = 0;
    end

    for (genvar i = 0; i < 4*SHARES; i=i+1) begin
        assign _Bmul1xDI[i] = 0;
    end

    for (genvar i = 0; i < 2*SHARES; i=i+1) begin
        assign _Binv1xDI[i] = 0;
        assign _Binv2xDI[i] = 0;
        assign _Binv3xDI[i] = 0;
    end

    aes_box #(.PIPELINED(PIPELINED), .EIGHT_STAGED(EIGHT_STAGED), .SHARES(SHARES))
    inst_aes_box (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_XxDI),
        ._Zmul1xDI(_Zmul1xDI),
        ._Zmul2xDI(_Zmul2xDI),
        ._Zmul3xDI(_Zmul3xDI),
        ._Zinv1xDI(_Zinv1xDI),
        ._Zinv2xDI(_Zinv2xDI),
        ._Zinv3xDI(_Zinv3xDI),
        ._Bmul1xDI(_Bmul1xDI),
        ._Binv1xDI(_Binv1xDI),
        ._Binv2xDI(_Binv2xDI),
        ._Binv3xDI(_Binv3xDI),
        ._QxDO(_QxDO)
    );

    // Create clock
	always@(*) #Td ClkxCI<=~ClkxCI;

	initial begin
        ClkxCI = 0;
		RstxBI = 0;
        for (integer k = 0; k < SHARES; k=k+1) begin
			XxDI[k] <= 0;
			/* code */
		end
		#T;
		RstxBI = 1;
		#T;


        /*
        for (integer i = 0; i < SHARES; i = i + 1) begin
            XxDI[i] <= 8'b00000000;
            #T;
            XxDI[i] <= 8'b00000001;
            #T;
            XxDI[i] <= 8'b00000010;
            #T;
            XxDI[i] <= 8'b00000011;
            #T;
            XxDI[i] <= 8'b00000100;
            #T;
            XxDI[i] <= 8'b00000101;
            #T;
            XxDI[i] <= 8'b00000110;
            #T;
            XxDI[i] <= 8'b00000111;
            #T;
            XxDI[i] <= 8'b00001000;
            #T;
            XxDI[i] <= 8'b00001001;
            #T;
            XxDI[i] <= 8'b00001010;
            #T;
            XxDI[i] <= 8'b00001011;
            #T;
            XxDI[i] <= 8'b00001100;
            #T;
            XxDI[i] <= 8'b00001101;
            #T;
            XxDI[i] <= 8'b00001110;
            #T;
            XxDI[i] <= 8'b00001111;
            #T;
        end
        */
        for (integer i = 0; i < 256; i = i + 1) begin
                XxDI[0] = i;
                #T;
        end
        #T;
        
    end


endmodule