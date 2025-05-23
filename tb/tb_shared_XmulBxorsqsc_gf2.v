`timescale 1ns/1ps
module tb_shared_XmulBxorsqsc_gf2();

localparam T=2.0;
localparam Td = T/2.0;

localparam N = 2;
localparam SHARES=2;

// General signals
reg ClkxCI;
// reg RstxBI;

reg [1:0] XxDI [SHARES-1 : 0];
reg [1:0] BxDI [SHARES-1 : 0];
wire [1:0] QxDO [SHARES-1 : 0];

wire [2*SHARES-1 : 0] _XxDI;
wire [2*SHARES-1 : 0] _YxDI;
wire [SHARES*(SHARES-1)-1 : 0] _ZxDI;
wire [2*SHARES-1 : 0] _BxDI;
wire [2*SHARES-1 : 0] _QxDO;

reg [1:0] X;
reg [1:0] B;
reg [1:0] Q;

for (genvar i = 0; i < SHARES; i=i+1) begin
	for (genvar j = 0; j < 2; j=j+1) begin
	assign _XxDI[i*2+j] = XxDI[i][j];
	assign _BxDI[i*2+j] = BxDI[i][j];
    assign _YxDI[i*2+j] = BxDI[i][j];
	assign QxDO[i][j] = _QxDO[i*2+j];
	end
end

for (genvar i = 0; i < SHARES*(SHARES-1); i=i+1) begin
	assign _ZxDI[i] = $random;
end

shared_XmulBxorsqsc_gf2 #(.PIPELINED(1), .FIRST_ORDER_OPTIMIZATION(0), .SHARES(SHARES)) inst_shared_XmulBxorsqsc_gf2(
	.ClkxCI(ClkxCI),
	// .RstxBI(RstxBI),
	._XxDI(_XxDI), 
    ._BxDI(_BxDI),
	._YxDI(_YxDI), 
	._ZxDI(_ZxDI), 
	._QxDO(_QxDO));


// Create clock
always@(*) #Td ClkxCI<=~ClkxCI;

initial begin
	ClkxCI = 0;
	// RstxBI = 0;

	for (integer k = 0; k < SHARES; k=k+1) begin
		XxDI[k] <= 0;
		BxDI[k] <= 0;
	end
	#T;
	// RstxBI = 1;
	#T;

	//alternative version
	for (integer i = 0; i < 2**N; i = i+1) begin
        for (integer j = 0; j < 2**N; j = j+1) begin
            XxDI[1] <= i;
            BxDI[1] <= j;
            for (integer a = 0; a < 2**N; a = a + 1) begin
                for (integer b = 0; b < 2**N; b = b + 1) begin
                    XxDI[0] <= a;
                    BxDI[0] <= b;
                    X = 2'b00;
                    B = 2'b00;
                    Q = 2'b00;
                    for (integer k = 0; k < SHARES; k=k+1) begin
                        X = X ^ XxDI[k];
                        B = B ^ BxDI[k];
                        Q = Q ^ QxDO[k];
                    end
                    #T;
                end
            end
        end
    end
end

endmodule
