module lin_map_wrong
#
(
    parameter MATRIX_SEL = 1
    /*
    0: S-Box input
    1: S-Box output
    */
)
(
    DataInxDI,
    DataOutxDO
);
input [7:0] DataInxDI;
output [7:0] DataOutxDO;

generate
    // AES input transformation
    if (MATRIX_SEL == 0) begin
        reg [7:0] Q;
        wire [7:0] INV_X [7:0];
        assign INV_X[0] = 8'b11100111; //是否需要反过来？？
        assign INV_X[1] = 8'b01110001;
        assign INV_X[2] = 8'b01100011;
        assign INV_X[3] = 8'b11100001;
        assign INV_X[4] = 8'b10011011;
        assign INV_X[5] = 8'b00000001;
        assign INV_X[6] = 8'b01100001;
        assign INV_X[7] = 8'b01001111;
        
        //assign Q = 8'b00000000;
        always @(MATRIX_SEL or Q or INV_X or DataInxDI or DataOutxDO) begin
            Q = 8'b00000000;
            for (integer y = 0; y < 8; y = y + 1) begin
                for (integer x = 0; x < 8; x = x + 1) begin
                    Q[7-y] = Q[7-y] ^ (DataInxDI[7-y] & INV_X[y][7-x]); //矩阵索引？？
                end
            end
        end
        
        /*
        for (genvar y = 0; y < 8; y = y + 1) begin
            for (genvar x = 0; x < 8; x = x + 1) begin
                assign Q[7-y] = Q[7-y] ^ (DataInxDI[7-y] & INV_X[y][7-x]); //矩阵索引？？
            end
        end
        */
        
        for (genvar i = 0; i < 8; i = i + 1) begin
            assign DataOutxDO[i] = Q[i];
        end
    end

    // AES output transformation
    if (MATRIX_SEL == 1) begin
        wire [7:0] Q;
        wire [7:0] MX [7:0];
        assign MX[0] = 8'b00101000; //是否需要反过来？？
        assign MX[1] = 8'b10001000;
        assign MX[2] = 8'b01000001;
        assign MX[3] = 8'b10101000;
        assign MX[4] = 8'b11111000;
        assign MX[5] = 8'b01101101;
        assign MX[6] = 8'b00110010;
        assign MX[7] = 8'b01010010;
        
        assign Q = 8'b00000000;
        for (genvar y = 0; y < 8; y = y + 1) begin
            for (genvar x = 0; x < 8; x = x + 1) begin
                assign Q[7-y] = Q[7-y] ^ (DataInxDI[7-y] & MX[y][7-x]); //矩阵索引？？
            end
        end
        
        for (genvar i = 0; i < 8; i = i + 1) begin
            assign DataOutxDO[i] = Q[i];
        end
    end
    
endgenerate
    
endmodule