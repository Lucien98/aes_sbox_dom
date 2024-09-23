`timescale  1ns / 1ps
module tb_lin_map_wrong();
    localparam T=2.0;
	localparam Td = T/2.0;

    localparam MATRIX_SEL = 1;

    // General signals
	reg clk = 1;
	//reg rst;

    reg [7:0] DataInxDI;
    wire [7:0] DataOutxDO;

    lin_map_wrong #(.MATRIX_SEL(MATRIX_SEL)) inst_lin_map_wrong (
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

/*
module tb_lin_map();

// lin_map Parameters      
parameter PERIOD      = 10;
parameter MATRIX_SEL  = 1; 

// lin_map Inputs
reg   [7:0]  DataInxDI                     = 0 ;

// lin_map Outputs
wire  [7:0]  DataOutxDO                    ;


initial
begin
    forever #(PERIOD/2)  clk=~clk;
end

initial
begin
    #(PERIOD*2) rst_n  =  1;
end

lin_map #(
    .MATRIX_SEL ( MATRIX_SEL ))
 u_lin_map (
    .DataInxDI               ( DataInxDI   [7:0] ),

    .DataOutxDO              ( DataOutxDO  [7:0] )
);

initial
begin

    $finish;
end

endmodule
*/