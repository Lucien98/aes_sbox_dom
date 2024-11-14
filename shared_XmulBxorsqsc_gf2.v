// X*B
// X与Y做square scaler
// X*B中的随机数为Z
// 未作inverse操作

module shared_XmulBxorsqsc_gf2
#
(
    parameter PIPELINED = 1,
    parameter SHARES = 2
)
(
    ClkxCI,
    RstxBI,
    _XxDI,
    _BxDI,
    _YxDI,
    _ZxDI,
    _QxDO
);
input ClkxCI;
input RstxBI;


input [2*SHARES-1 : 0] _XxDI;
input [2*SHARES-1 : 0] _BxDI;
input [2*SHARES-1 : 0] _YxDI;
input [SHARES*(SHARES-1)-1 : 0] _ZxDI;
output [2*SHARES-1 : 0] _QxDO;

wire [1:0] XxDI [SHARES-1 : 0];
wire [1:0] BxDI [SHARES-1 : 0];
wire [1:0] YxDI [SHARES-1 : 0];
wire [1:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [1:0] QxDO [SHARES-1 : 0];


genvar i;
genvar j;

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*2+j];
        assign BxDI[i][j] = _BxDI[i*2+j];
        assign YxDI[i][j] = _YxDI[i*2+j];
        assign _QxDO[i*2+j] = QxDO[i][j];
    end
end

for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign ZxDI[i][j] = _ZxDI[i*2+j];
    end
end

// Intermediates
wire [1:0] Xi_mul_Bj [SHARES*SHARES-1:0];

// Synchronization FF's
reg [1:0] FFxDN     [SHARES*SHARES-1:0];
reg [1:0] FFxDP     [SHARES*SHARES-1:0];

wire [1:0] Y0xorY1xD [SHARES-1 : 0];
wire [1:0] Y0xorY12xD [SHARES-1 : 0];


for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < SHARES; j=j+1) begin
        gf2_mul #(.N(2)) inst_gf2_mul(
            .AxDI(XxDI[i]),
            .BxDI(BxDI[j]),
            .QxDO(Xi_mul_Bj[SHARES*i + j])
        );
    end
end

for (i = 0; i < SHARES; i=i+1) begin
    assign Y0xorY1xD[i] = XxDI[i] ^ YxDI[i];
    scale square_scaler_2_inst (
        .a(Y0xorY1xD[i]),
        .q(Y0xorY12xD[i])
    );
end

// purpose: Register process
// type   : sequential
// inputs : ClkxCI, RstxBI
// outputs: 

// async
always @(posedge ClkxCI or negedge RstxBI) begin : proc_
    integer k;
    integer l;
    if (~RstxBI) begin
        for (k = 0; k < SHARES; k=k+1) begin
            for (l = 0; l < SHARES; l=l+1) begin
                FFxDP[SHARES*k + l] <= 2'b0; 
            end
        end
    end else begin
        for (k = 0; k < SHARES; k=k+1) begin
            for (l = 0; l < SHARES; l=l+1) begin
                FFxDP[SHARES*k + l] <= FFxDN[SHARES*k + l];
            end
        end
    end
end

reg [1:0] result [SHARES-1:0];
for (i = 0; i < SHARES; i=i+1) begin
    assign QxDO[i] = result[i];
end

//////////////////////////////////////////////////////////////////
// Masked Multiplier Nth order secure for odd number of shares, pipelined
if (PIPELINED == 1) begin
// purpose: implements the shared multiplication in a secure and generic way
// type   : combinational
// inputs : 
// outputs: 
    integer k;
    integer l;
    always @(*) begin
        for (k = 0; k < SHARES; k=k+1) begin
            result[k] = 2'b00;
            for (l = 0; l < SHARES; l=l+1) begin
                if (k==l) begin
                    FFxDN[SHARES*k + l] = Xi_mul_Bj[SHARES*k + l] ^ Y0xorY12xD[k];             // domain term
                end
                else if (l > k) begin
                    FFxDN[SHARES*k + l] = Xi_mul_Bj[SHARES*k + l] ^ ZxDI[k + l*(l-1)/2];  // regular term
                end
                else begin
                    FFxDN[SHARES*k + l] = Xi_mul_Bj[SHARES*k + l] ^ ZxDI[l + k*(k-1)/2];  // transposed
                end
                result[k] = result[k] ^ FFxDP[SHARES*k + l];
            end
        end
    end
end


endmodule



// sqsc和mul相加之后，要inverse