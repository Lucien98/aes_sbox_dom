module shared_sqscmul_gf4
#
(
    parameter PIPELINED = 1,
    parameter SHARES = 4
)
(
    ClkxCI,
    // RstxBI,
    _XxDI,
    _YxDI,
    _ZxDI,
    _BxDI,
    _QxDO
);
`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);
input ClkxCI;
// input RstxBI;

input [4*SHARES-1 : 0] _XxDI;
input [4*SHARES-1 : 0] _YxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _ZxDI;
input [4*blind_n_rnd-1 : 0] _BxDI;
output [4*SHARES-1 : 0] _QxDO;

wire [3:0] XxDI [SHARES-1 : 0];
wire [3:0] YxDI [SHARES-1 : 0];
wire [3:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [3:0] QxDO [SHARES-1 : 0];

genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*4+j];
        assign YxDI[i][j] = _YxDI[i*4+j];
        assign _QxDO[i*4+j] = QxDO[i][(j+2)%4];
    end
end

for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign ZxDI[i][j] = _ZxDI[i*4+j];
    end
end

// Intermediates
wire [3:0] Xi_mul_Yj [SHARES*SHARES-1:0];

// Synchronization FF's
reg [3:0] FFxDN     [SHARES*SHARES-1:0];
reg [3:0] FFxDP     [SHARES*SHARES-1:0];

wire [3:0] Y0xorY1xD [SHARES-1 : 0];
wire [3:0] Y0xorY12xD [SHARES-1 : 0]; 


for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < SHARES; j=j+1) begin
        gf2_mul #(.N(4)) inst_gf4_mul(
            .AxDI(XxDI[i]),
            .BxDI(YxDI[j]),
            .QxDO(Xi_mul_Yj[SHARES*i + j])
        );
    end
end

for (i = 0; i < SHARES; i=i+1) begin
    assign Y0xorY1xD[i] = XxDI[i] ^ YxDI[i];
    square_scaler square_scaler_inst (
        .DataInxDI(Y0xorY1xD[i]),
        .DataOutxDO(Y0xorY12xD[i])
    );
end

// purpose: Register process
// type   : sequential
// inputs : ClkxCI, RstxBI
// outputs: 

// async
always @(posedge ClkxCI /*or negedge RstxBI*/) begin : proc_
    integer k;
    integer l;
    // if(~RstxBI) begin
    //     for (k = 0; k < SHARES; k=k+1) begin
    //         for (l = 0; l < SHARES; l=l+1) begin
    //             FFxDP[SHARES*k + l] <= 4'b0000; 
    //         end
    //     end
    // end else begin
        for (k = 0; k < SHARES; k=k+1) begin
            for (l = 0; l < SHARES; l=l+1) begin
                FFxDP[SHARES*k + l] <= FFxDN[SHARES*k + l];
            end
        end
    // end
end


reg [3:0] result [SHARES-1:0];
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
            result[k] = 4'b0000;
            for (l = 0; l < SHARES; l=l+1) begin
                if (k==l) begin
                    FFxDN[SHARES*k + l] = Xi_mul_Yj[SHARES*k + l] ^ Y0xorY12xD[k] ^ _BxDI;             // domain term
                end
                else if (l > k) begin
                    FFxDN[SHARES*k + l] = Xi_mul_Yj[SHARES*k + l] ^ ZxDI[k + l*(l-1)/2];  // regular term
                end
                else begin
                    FFxDN[SHARES*k + l] = Xi_mul_Yj[SHARES*k + l] ^ ZxDI[l + k*(k-1)/2];  // transposed
                end
                result[k] = result[k] ^ FFxDP[SHARES*k + l];
            end
        end
    end
end

endmodule
