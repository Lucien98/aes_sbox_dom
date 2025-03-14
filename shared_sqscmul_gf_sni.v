module shared_sqscmul_gf_sni
#
(
    parameter PIPELINED = 1,
    parameter SHARES = 2,
    parameter N = 4
)
(
    ClkxCI,
    _XxDI,
    _YxDI,
    _ZxDI,
    _QxDO
);
input ClkxCI;


input [N*SHARES-1 : 0] _XxDI;
input [N*SHARES-1 : 0] _YxDI;
input [N*SHARES*(SHARES-1)-1 : 0] _ZxDI;
output [N*SHARES-1 : 0] _QxDO;

wire [N-1:0] XxDI [SHARES-1 : 0];
wire [N-1:0] YxDI [SHARES-1 : 0];
wire [N-1:0] Z1xDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [N-1:0] Z2xDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [N-1:0] QxDO [SHARES-1 : 0];

genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < N; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*N+j];
        assign YxDI[i][j] = _YxDI[i*N+j];
        assign _QxDO[i*N+j] = QxDO[i][(j+N/2)%N];
    end
end

for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < N; j=j+1) begin
        assign Z1xDI[i][j] = _ZxDI[i*N+j];
        assign Z2xDI[i][j] = _ZxDI[N/2*SHARES*(SHARES-1) + i*N+j];
    end
end

reg [N-1:0] Share0 [SHARES*SHARES-1:0];
if (SHARES == 3) begin
    always @(posedge ClkxCI) begin : proc_share0
        integer k;
        for (k = 0; k < SHARES; k = k + 1) begin
            Share0[k] = Z1xDI[k];
            Share0[k+3] = Z1xDI[k] ^ Z2xDI[k];
            Share0[k+6] = Z2xDI[k];
        end
    end
end else if (SHARES == 2) begin
    always @(*) begin
        Share0[0] = Z1xDI[0];
        Share0[1] = Z2xDI[0];
        Share0[2] = Z1xDI[0];
        Share0[3] = Z2xDI[0];
    end
end


// Intermediates
wire [N-1:0] Xi_mul_Yj [SHARES*SHARES-1:0];

// Synchronization FF's
reg [N-1:0] FFxDN     [SHARES*SHARES-1:0];
reg [N-1:0] FFxDP     [SHARES*SHARES-1:0];

wire [N-1:0] Y0xorY1xD [SHARES-1 : 0];
wire [N-1:0] Y0xorY12xD [SHARES-1 : 0]; 


for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < SHARES; j=j+1) begin
        gf2_mul #(.N(N)) inst_gf4_mul(
            .AxDI(XxDI[i]),
            .BxDI(YxDI[j]),
            .QxDO(Xi_mul_Yj[SHARES*i + j])
        );
    end
end

for (i = 0; i < SHARES; i=i+1) begin
    assign Y0xorY1xD[i] = XxDI[i] ^ YxDI[i];
if (N==4)
    square_scaler square_scaler_inst (
        .DataInxDI(Y0xorY1xD[i]),
        .DataOutxDO(Y0xorY12xD[i])
    );
else
    scale scaler_inst (
        .a(Y0xorY1xD[i]),
        .q(Y0xorY12xD[i])
    );
end

// purpose: Register process
// type   : sequential
// inputs : ClkxCI, RstxBI
// outputs: 

// async
always @(posedge ClkxCI) begin : proc_
    integer k;
    integer l;
    for (k = 0; k < SHARES; k=k+1) begin
        for (l = 0; l < SHARES; l=l+1) begin
            FFxDP[SHARES*k + l] <= FFxDN[SHARES*k + l];
        end
    end
end


reg [N-1:0] result [SHARES-1:0];
for (i = 0; i < SHARES; i=i+1) begin
    assign QxDO[i] = result[i];
end

//////////////////////////////////////////////////////////////////
// Masked Multiplier Nth order secure for odd number of shares, pipelined
// generate
if (PIPELINED == 1) begin
// purpose: implements the shared multiplication in a secure and generic way
// type   : combinational
// inputs : 
// outputs: 
    integer k;
    integer l;
    always @(*) begin
        for (k = 0; k < SHARES; k=k+1) begin
            result[k] = 0;
            for (l = 0; l < SHARES; l=l+1) begin
                if (k==l) begin
                    FFxDN[SHARES*k + l] = Xi_mul_Yj[SHARES*k + l] ^ Y0xorY12xD[k] ^ Share0[SHARES*k + l];             // domain term
                end
                else if (l > k) begin
                    FFxDN[SHARES*k + l] = Xi_mul_Yj[SHARES*k + l] ^ Share0[SHARES*k + l];  // regular term
                end
                else begin
                    FFxDN[SHARES*k + l] = Xi_mul_Yj[SHARES*k + l] ^ Share0[SHARES*k + l];  // transposed
                end
                result[k] = result[k] ^ FFxDP[SHARES*k + l];
            end
        end
    end
end

endmodule
