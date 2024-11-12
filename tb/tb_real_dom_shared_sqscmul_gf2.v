//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/8/29 14:13:44
// Design Name: 
// Module Name: tb_shared_mul_gf4prime / Behavioral
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 / File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


`timescale 1ns/1ps
module tb_real_dom_shared_sqscmul_gf2();

localparam T=2.0;
localparam Td = T/2.0;

localparam N = 2;
localparam SHARES=2;

// General signals
reg ClkxCI;
reg RstxBI;

reg [1:0] XxDI [SHARES-1 : 0];
reg [1:0] YxDI [SHARES-1 : 0];
// reg [1:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [1:0] QxDO [SHARES-1 : 0];

wire [2*SHARES-1 : 0] _XxDI;
wire [2*SHARES-1 : 0] _YxDI;
wire [SHARES*(SHARES-1)-1 : 0] _ZxDI;
wire [2*SHARES-1 : 0] _BxDI;
wire [2*SHARES-1 : 0] _QxDO;

reg [1:0] X;
reg [1:0] Y;
reg [1:0] Q;

for (genvar i = 0; i < SHARES; i=i+1) begin
	for (genvar j = 0; j < 2; j=j+1) begin
	assign _XxDI[i*2+j] = XxDI[i][j];
	assign _YxDI[i*2+j] = YxDI[i][j];
    assign _BxDI[i*2+j] = $random;
	assign QxDO[i][j] = _QxDO[i*2+j];
	end
end

for (genvar i = 0; i < SHARES*(SHARES-1); i=i+1) begin
	assign _ZxDI[i] = $random;
end

real_dom_shared_sqscmul_gf2 #(.PIPELINED(1), .FIRST_ORDER_OPTIMIZATION(1), .SHARES(SHARES)) inst_real_dom_shared_sqscmul_gf2(
	.ClkxCI(ClkxCI),
	.RstxBI(RstxBI),
	._XxDI(_XxDI), 
	._YxDI(_YxDI), 
	._ZxDI(_ZxDI), 
    ._BxDI(_BxDI),
	._QxDO(_QxDO));

// Create clock
always@(*) #Td ClkxCI<=~ClkxCI;

initial begin
	ClkxCI = 0;
	RstxBI = 0;

	for (integer k = 0; k < SHARES; k=k+1) begin
		XxDI[k] <= 0;
		YxDI[k] <= 0;
	end
	#T;
	RstxBI = 1;
	#T;

	//alternative version
	for (integer i = 0; i < 2**N; i = i+1) begin
        for (integer j = 0; j < 2**N; j = j+1) begin
            XxDI[1] <= i;
            YxDI[1] <= j;
            for (integer a = 0; a < 2**N; a = a + 1) begin
                for (integer b = 0; b < 2**N; b = b + 1) begin
                    XxDI[0] <= a;
                    YxDI[0] <= b;
//                    _ZxDI = $random;
//                    _BxDI = $random;
                    X = 2'b00;
                    Y = 2'b00;
                    Q = 2'b00;
                    for (integer k = 0; k < SHARES; k=k+1) begin
                        X = X ^ XxDI[k];
                        Y = Y ^ YxDI[k];
                        Q = Q ^ QxDO[k];
                    end
                    #T;
                end
            end
        end
    end
end

endmodule
