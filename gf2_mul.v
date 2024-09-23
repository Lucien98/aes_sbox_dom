module gf2_mul
#
(
    parameter N = 1
)
(
    AxDI,
    BxDI,
    QxDO
);
input [N-1:0] AxDI;
input [N-1:0] BxDI;
output [N-1:0] QxDO;

generate
    wire [N-1:0] Q;

    if (N==1) begin
        assign Q = AxDI & BxDI;
    end

    if (N==2) begin
        wire [N-1:0] A;
        wire [N-1:0] B;
        wire [N-1:0] Q_norm;

        assign A[0] = AxDI[0];
        assign A[1] = AxDI[1];
        assign B[0] = BxDI[0];
        assign B[1] = BxDI[1];

        assign Q_norm[0] = ((A[1] ^ A[0]) & (B[1] ^ B[0])) ^ (A[0] & B[0]);
        assign Q_norm[1] = ((A[1] ^ A[0]) & (B[1] ^ B[0])) ^ (A[1] & B[1]);
        
        assign Q[0] = Q_norm[0];
        assign Q[1] = Q_norm[1];
    end

    if (N==4) begin
        wire [3:0] A;
        wire [3:0] B;
        wire [3:0] Q_norm;
        wire [1:0] PH;
        wire [1:0] PL;
        wire [1:0] P;
        wire [1:0] AA;
        wire [1:0] BB;

        assign A[3] = AxDI[3];
        assign A[2] = AxDI[2];
        assign A[1] = AxDI[1];
        assign A[0] = AxDI[0];
        
        assign B[3] = BxDI[3];
        assign B[2] = BxDI[2];
        assign B[1] = BxDI[1];
        assign B[0] = BxDI[0];
        
        // HI MUL GF2^4 multiplier
        assign PH[0] = ((A[3] ^ A[2]) & (B[3] ^ B[2])) ^ (A[2] & B[2]);
        assign PH[1] = ((A[3] ^ A[2]) & (B[3] ^ B[2])) ^ (A[3] & B[3]);
        
        // LO MUL GF2^4 multiplier
        assign PL[0] = ((A[1] ^ A[0]) & (B[1] ^ B[0])) ^ (A[0] & B[0]);
        assign PL[1] = ((A[1] ^ A[0]) & (B[1] ^ B[0])) ^ (A[1] & B[1]);

        // MUL and SQUARE SCALE
        assign AA = {A[3], A[2]} ^ {A[1], A[0]};
        assign BB = {B[3], B[2]} ^ {B[1], B[0]};

        assign P[1] = ((AA[1] ^ AA[0]) & (BB[1] ^ BB[0])) ^ (AA[0] & BB[0]);
        assign P[0] = ((AA[1] ^ AA[0]) & (BB[1] ^ BB[0])) ^ (AA[1] & BB[1]) ^ P[1];

        // Output assignment
        assign Q_norm = {(PH ^ P), (PL ^ P)};

        // Linear mapping:
        assign Q[3] = Q_norm[3];
        assign Q[2] = Q_norm[2];
        assign Q[1] = Q_norm[1];
        assign Q[0] = Q_norm[0];
    end

    assign QxDO = Q;
endgenerate

endmodule
