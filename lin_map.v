module lin_map
#
(
    parameter MATRIX_SEL = 0
    /*
    0: S-Box output
    1: S-Box input
    */
)
(
    DataInxDI,
    DataOutxDO
);
input [7:0] DataInxDI;
output [7:0] DataOutxDO;

// intermediate;
wire				R1;
wire				R2;
wire				R3;
wire				R4;
wire				R5;
wire				R6;
wire				R7;
wire				R8;
wire				R9;

wire	[07:00]		B;

if (MATRIX_SEL == 1) begin
    assign R1 =  DataInxDI[7] ^ DataInxDI[5];
    assign R2 = ~DataInxDI[7] ^ DataInxDI[4];
    assign R3 =  DataInxDI[6] ^ DataInxDI[0];
    assign R4 = ~DataInxDI[5] ^ R3;
    assign R5 =  DataInxDI[4] ^ R4;
    assign R6 =  DataInxDI[3] ^ DataInxDI[0];
    assign R7 =  DataInxDI[2] ^ R1;
    assign R8 =  DataInxDI[1] ^ R3;
    assign R9 =  DataInxDI[3] ^ R8;

    assign B[7] = ~R7 ^ R8;
    assign B[6] =  R5;
    assign B[5] =  DataInxDI[1] ^ R4;
    assign B[4] = ~R1 ^ R3;
    assign B[3] =  DataInxDI[1] ^ R2 ^ R6;
    assign B[2] = ~DataInxDI[0];
    assign B[1] =  R4;
    assign B[0] = ~DataInxDI[2] ^ R9;

    assign DataOutxDO = ~B;
end
else if (MATRIX_SEL == 0) begin
    assign R1 =  DataInxDI[7] ^ DataInxDI[3];
	assign R2 =  DataInxDI[6] ^ DataInxDI[4];
	assign R3 =  DataInxDI[6] ^ DataInxDI[0];
	assign R4 = ~DataInxDI[5] ^ DataInxDI[3];
	assign R5 = ~DataInxDI[5] ^ R1;
	assign R6 = ~DataInxDI[5] ^ DataInxDI[1];
	assign R7 = ~DataInxDI[4] ^ R6;
	assign R8 =  DataInxDI[2] ^ R4;
	assign R9 =  DataInxDI[1] ^ R2;
	
	assign B[7] = R4;
	assign B[6] = R1;
	assign B[5] = R3;
	assign B[4] = R5;
	assign B[3] = R2 ^ R5;
	assign B[2] = R3 ^ R8;
	assign B[1] = R7;
	assign B[0] = R9;
	
	assign DataOutxDO[7]   = ~B[7];
	assign DataOutxDO[6:5] =  B[6:5];
	assign DataOutxDO[4:2] = ~B[4:2];
	assign DataOutxDO[1:0] =  B[1:0];
end

endmodule





/*
module lin_map
#
(
    parameter MATRIX_SEL = 0
)
(
    DataInxDI,
    DataOutxDO
);
input [7:0] DataInxDI;
output [7:0] DataOutxDO;

// intermediate;
wire				R1;
wire				R2;
wire				R3;
wire				R4;
wire				R5;
wire				R6;
wire				R7;
wire				R8;
wire				R9;

wire	[07:00]		B;

if (MATRIX_SEL == 1) begin
    assign R1 =  DataInxDI[7-7] ^ DataInxDI[7-5];
    assign R2 = ~DataInxDI[7-7] ^ DataInxDI[7-4];
    assign R3 =  DataInxDI[7-6] ^ DataInxDI[7-0];
    assign R4 = ~DataInxDI[7-5] ^ R3;
    assign R5 =  DataInxDI[7-4] ^ R4;
    assign R6 =  DataInxDI[7-3] ^ DataInxDI[7-0];
    assign R7 =  DataInxDI[7-2] ^ R1;
    assign R8 =  DataInxDI[7-1] ^ R3;
    assign R9 =  DataInxDI[7-3] ^ R8;

    assign B[7-7] = ~R7 ^ R8;
    assign B[7-6] =  R5;
    assign B[7-5] =  DataInxDI[1] ^ R4;
    assign B[7-4] = ~R1 ^ R3;
    assign B[7-3] =  DataInxDI[1] ^ R2 ^ R6;
    assign B[7-2] = ~DataInxDI[0];
    assign B[7-1] =  R4;
    assign B[7-0] = ~DataInxDI[2] ^ R9;

    assign DataOutxDO = ~B;
end
else if (MATRIX_SEL == 0) begin
    assign R1 =  DataInxDI[7-7] ^ DataInxDI[7-3];
	assign R2 =  DataInxDI[7-6] ^ DataInxDI[7-4];
	assign R3 =  DataInxDI[7-6] ^ DataInxDI[7-0];
	assign R4 = ~DataInxDI[7-5] ^ DataInxDI[7-3];
	assign R5 = ~DataInxDI[7-5] ^ R1;
	assign R6 = ~DataInxDI[7-5] ^ DataInxDI[7-1];
	assign R7 = ~DataInxDI[7-4] ^ R6;
	assign R8 =  DataInxDI[7-2] ^ R4;
	assign R9 =  DataInxDI[7-1] ^ R2;
	
	assign B[7-7] = R4;
	assign B[7-6] = R1;
	assign B[7-5] = R3;
	assign B[7-4] = R5;
	assign B[7-3] = R2 ^ R5;
	assign B[7-2] = R3 ^ R8;
	assign B[7-1] = R7;
	assign B[7-0] = R9;
	
	assign DataOutxDO[7]   = ~B[7];
	assign DataOutxDO[6:5] =  B[6:5];
	assign DataOutxDO[4:2] = ~B[4:2];
	assign DataOutxDO[1:0] =  B[1:0];
end

endmodule
*/