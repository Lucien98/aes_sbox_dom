module square_scaler
(
    DataInxDI,
    DataOutxDO
);
input [3:0] DataInxDI;
output [3:0] DataOutxDO;

generate
    assign DataOutxDO[3] = DataInxDI[0] ^ DataInxDI[2];
    assign DataOutxDO[2] = DataInxDI[1] ^ DataInxDI[3];
    assign DataOutxDO[1] = DataInxDI[1] ^ DataInxDI[0];
    assign DataOutxDO[0] = DataInxDI[0];
endgenerate
    
endmodule