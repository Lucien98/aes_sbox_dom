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

// assign DataOutxDO = DataInxDI;

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
else if (MATRIX_SEL == 2) begin
	assign DataOutxDO = DataInxDI;
end
else if (MATRIX_SEL == 3) begin
    // assign R1 =  DataInxDI[6] ^ DataInxDI[3];
	// assign R2 =  DataInxDI[4] ^ DataInxDI[1];
	// assign R3 =  DataInxDI[7] ^ DataInxDI[0];
	// assign R4 =  DataInxDI[5] ^ DataInxDI[1];
	// assign R5 =  DataInxDI[5] ^ R1;
	// assign R6 =  DataInxDI[5] ^ DataInxDI[7];
	// assign R7 =  DataInxDI[2] ^ R5;
	// assign R8 =  DataInxDI[1] ^ DataInxDI[6];
	// assign R9 =  DataInxDI[1] ^ R3;
	
	// assign B[7] = R2;
	// assign B[6] = R5 ^ R9;
	// assign B[5] = R3 ^ R7;
	// assign B[4] = R8;
	// assign B[3] = R2 ^ R7;
	// assign B[2] = R2 ^ R6;
	// assign B[1] = R4;
	// assign B[0] = DataOutxDO[2];
    wire x0, x1, x2, x3, x4, x5, x6, x7;
    assign {x7, x6, x5, x4, x3, x2, x1, x0} = DataInxDI;

    wire x8 ; assign x8  = x1 ^ x6; // depth 1
    wire x9 ; assign x9  = x0 ^ x6; // depth 1
    wire x10; assign x10 = x3 ^ x5; // depth 1
    wire x11; assign x11 = x2 ^ x10; // depth 2
    wire x12; assign x12 = x1 ^ x4; // depth 1
    wire x13; assign x13 = x3 ^ x7; // depth 1
    wire x14; assign x14 = x9 ^ x11; // depth 3
    wire x15; assign x15 = x7 ^ x10; // depth 2
    wire x16; assign x16 = x2 ^ x9; // depth 2
    wire x17; assign x17 = x5 ^ x12; // depth 2
    wire x18; assign x18 = x7 ^ x17; // depth 3
    wire x19; assign x19 = x4 ^ x8; // depth 2
    wire x20; assign x20 = x11 ^ x19; // depth 3
    wire x21; assign x21 = x15 ^ x16; // depth 3
    wire x22; assign x22 = x1 ^ x5; // depth 1
    wire x23; assign x23 = x13 ^ x22; // depth 2
    wire x24; assign x24 = x19 ^ x23; // depth 3
    wire x25; assign x25 = x9 ^ x23; // depth 3
	
	// assign DataOutxDO   = B;
    wire y8 ; assign y8  = x2; // depth 0
    wire y9 ; assign y9  = x22; // depth 1
    wire y10; assign y10 = x18; // depth 3
    wire y11; assign y11 = x20; // depth 3
    wire y12; assign y12 = x8; // depth 1
    wire y13; assign y13 = x21; // depth 3
    wire y14; assign y14 = x25; // depth 3
    wire y15; assign y15 = x12; // depth 1
    assign DataOutxDO = {y15, y14, y13, y12, y11, y10, y9, y8};

end
endmodule
