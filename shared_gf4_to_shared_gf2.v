module shared_gf4_to_shared_gf2 #(
    parameter SHARES = 2
) (
    input [4*SHARES-1 : 0] _XxDI,
    output [2*SHARES-1 : 0] _A,
    output [2*SHARES-1 : 0] _B
);

    wire [3:0] XxDI [SHARES-1 : 0];
    wire [1:0] A [SHARES-1:0]; 
    wire [1:0] B [SHARES-1:0];

    genvar i, j;

    // 拆分输入
    for (i = 0; i < SHARES; i = i + 1) begin
        for (j = 0; j < 4; j = j + 1) begin
            assign XxDI[i][j] = _XxDI[i*4 + j];
        end
    end

    // 计算 A 和 B
    for (i = 0; i < SHARES; i = i + 1) begin
        assign A[i][1] = XxDI[i][3];
        assign A[i][0] = XxDI[i][2];
        assign B[i][1] = XxDI[i][1];
        assign B[i][0] = XxDI[i][0];
    end

    // 组合输出
    for (i = 0; i < SHARES; i = i + 1) begin
        for (j = 0; j < 2; j = j + 1) begin
            assign _A[i*2 + j] = A[i][j];
            assign _B[i*2 + j] = B[i][j];
        end
    end

endmodule
