`timescale 1ns/1ps
module tb_shared_mul_gf4();

	localparam T=2.0;
	localparam Td = T/2.0;

	localparam N = 4;
	localparam SHARES=2;

	// General signals
	reg ClkxCI;
	reg RstxBI;

	reg [3:0] XxDI [SHARES-1 : 0];
	reg [3:0] YxDI [SHARES-1 : 0];
	wire [3:0] QxDO [SHARES-1 : 0];

	wire [4*SHARES-1 : 0] _XxDI;
	wire [4*SHARES-1 : 0] _YxDI;
	wire [2*SHARES*(SHARES-1)-1 : 0] _ZxDI;
	wire [4*SHARES-1 : 0] _QxDO;

	for (genvar i = 0; i < SHARES; i=i+1) begin
	  for (genvar j = 0; j < 4; j=j+1) begin
	    assign _XxDI[i*4+j] = XxDI[i][j];
	    assign _YxDI[i*4+j] = YxDI[i][j];
	    assign QxDO[i][j] = _QxDO[i*4+j];
	  end
	end

  for (genvar i = 0; i < 2*SHARES*(SHARES-1); i=i+1) begin
  	assign _ZxDI[i] = 0;
  end

	shared_mul_gf4 #(.PIPELINED(1),.SHARES(SHARES)) inst_shared_mul_gf4(
		.ClkxCI(ClkxCI),
		.RstxBI(RstxBI),
		._XxDI(_XxDI), 
		._YxDI(_YxDI), 
		._ZxDI(_ZxDI), 
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
					XxDI[0] <= i;
					YxDI[0] <= j;
					for (integer k = 1; k < SHARES; k=k+1) begin
						XxDI[k] <= 0;
						YxDI[k] <= 0;
					end
				#T;
			end
		end
	end

endmodule
