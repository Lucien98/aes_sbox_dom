`timescale  1ns / 1ps
module tb_lin_map();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam MATRIX_SEL = 1;

    // General signals
	reg clk = 1;
	//reg rst;

    reg [7:0] DataInxDI;
    wire [7:0] DataOutxDO;

    lin_map #(.MATRIX_SEL(MATRIX_SEL)) inst_lin_map (
        .DataInxDI(DataInxDI),
        .DataOutxDO(DataOutxDO)
    );

    // Create clock
	always@(*) #Td clk<=~clk;
    
    initial begin
        //assign DataInxDI = 8'b10101010;
        for (integer i = 0; i < 256; i = i + 1) begin
                DataInxDI = i;
                #Td;
        end
        #Td;
    end


endmodule
