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
	reg RstxBI;

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

    for (genvar i = 0; i < SHARES*(SHARES-1); i=i+1) begin
        assign _Zmul1xDI[i] = 0;
        assign _Zmul2xDI[i] = 0;
        assign _Zmul3xDI[i] = 0;
    end

    for (genvar i = 0; i < 2*SHARES; i=i+1) begin
        assign _Bmul1xDI[i] = 0;
        assign _Bmul2xDI[i] = 0;
        assign _Bmul3xDI[i] = 0;
    end

    inverter #(.VARIANT(VARIANT), .PIPELINED(PIPELINED), .EIGHT_STAGED_SBOX(EIGHT_STAGED_SBOX), .SHARES(SHARES))
    inst_inverter (
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
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
		RstxBI = 0;
        for (integer k = 0; k < SHARES; k=k+1) begin
			XxDI[k] <= 0;
			/* code */
		end
		#T;
		RstxBI = 1;
		#T;

        //alternative version
        /*
        for (integer x = 0; x < SHARES; x = x + 1) begin
            for (integer i = 0; i < 2; i = i+1) begin
                XxDI[x][3] <= i;
                for (integer j = 0; j < 2; j=j+1) begin
                    XxDI[x][2] <= j;
                    for (integer k = 0; k < 2; k=k+1) begin
                        XxDI[x][1] <= k;
                        for (integer l = 0; l < 2; l=l+1) begin
                            XxDI[x][0] <= l;
                        end
                        #T;
                    end
                    #T;
                end
                #T;
            end
        end
        */
        for (integer i = 0; i < SHARES; i = i + 1) begin
            XxDI[i] <= 4'b0000;
            #T;
            XxDI[i] <= 4'b0001;
            #T;
            XxDI[i] <= 4'b0010;
            #T;
            XxDI[i] <= 4'b0011;
            #T;
            XxDI[i] <= 4'b0100;
            #T;
            XxDI[i] <= 4'b0101;
            #T;
            XxDI[i] <= 4'b0110;
            #T;
            XxDI[i] <= 4'b0111;
            #T;
            XxDI[i] <= 4'b1000;
            #T;
            XxDI[i] <= 4'b1001;
            #T;
            XxDI[i] <= 4'b1010;
            #T;
            XxDI[i] <= 4'b1011;
            #T;
            XxDI[i] <= 4'b1100;
            #T;
            XxDI[i] <= 4'b1101;
            #T;
            XxDI[i] <= 4'b1110;
            #T;
            XxDI[i] <= 4'b1111;
            #T;
        end
        
    end


endmodule