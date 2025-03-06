module shared_hpc3_sqscmul_gf4
#
(
    parameter PIPELINED = 1,
    parameter SHARES = 4
)
(
    ClkxCI,
    // RstxBI,
    _XxDI,
    _XxDI_prev,
    _YxDI,
    _ZxDI,
    _RxDI,
    _QxDO
);
input ClkxCI;
// input RstxBI;


input [4*SHARES-1 : 0] _XxDI;
input [4*SHARES-1 : 0] _XxDI_prev;
input [4*SHARES-1 : 0] _YxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _ZxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _RxDI;
output [4*SHARES-1 : 0] _QxDO;

wire [3:0] XxDI [SHARES-1 : 0];
reg [3:0] XxDP [SHARES-1 : 0];
reg [3:0] _XxD [SHARES-1 : 0];
wire [3:0] XxDI_prev [SHARES-1 : 0];
wire [3:0] YxDI [SHARES-1 : 0];
wire [3:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [3:0] RxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [3:0] QxDO [SHARES-1 : 0];

genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*4+j];
        assign XxDI_prev[i][j] = _XxDI_prev[i*4+j];
        assign YxDI[i][j] = _YxDI[i*4+j];
        assign _QxDO[i*4+j] = QxDO[i][j];
        // assign _XxD[i][j] = XxDP[i][j];
    end
end

for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign ZxDI[i][j] = _ZxDI[i*4+j];
        assign RxDI[i][j] = _RxDI[i*4+j];
    end
end

// Intermediates
wire [3:0] Xi_mul_Zij [SHARES*SHARES-1:0];

// Synchronization FF's
reg [3:0] FFxDN     [SHARES*SHARES-1:0];
reg [3:0] FFxDP     [SHARES*SHARES-1:0];

reg [3:0] ZijBlindedYjDN [SHARES*SHARES-1:0];
reg [3:0] ZijBlindedYjDP [SHARES*SHARES-1:0];
reg [3:0] SumBlindedYj [SHARES-1:0];

wire [3:0] Y0xorY1xD [SHARES-1 : 0];
wire [3:0] Y0xorY12xD [SHARES-1 : 0]; 

wire [3:0] Xi_mul_SumBlindedYj [SHARES-1 : 0];

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < SHARES; j=j+1) begin
        wire [3:0] InnerDomain;// 
        if ((i == ((j+1) % SHARES)) && (i < j)) begin
            gf2_mul #(.N(4)) inst_gf4_mul_inner_ilej(
                .AxDI(XxDI[i]),
                .BxDI(ZxDI[i + j*(j-1)/2] ^ YxDI[i]),
                .QxDO(InnerDomain)
            );
            assign Xi_mul_Zij[SHARES*i + j] = InnerDomain ^ Y0xorY12xD[i];
        end
        else if ((i == ((j+1) % SHARES)) && (i > j)) begin
            gf2_mul #(.N(4)) inst_gf4_mul_inner_igej(
                .AxDI(XxDI[i]),
                .BxDI(ZxDI[j + i*(i-1)/2] ^ YxDI[i]),
                .QxDO(InnerDomain)
            );
            assign Xi_mul_Zij[SHARES*i + j] = InnerDomain ^ Y0xorY12xD[i];            
        end
        else begin
            if (i < j) begin
                gf2_mul #(.N(4)) inst_gf4_mul_ilej(
                    .AxDI(XxDI[i]),
                    .BxDI(ZxDI[i + j*(j-1)/2]),
                    .QxDO(Xi_mul_Zij[SHARES*i + j])
                );
            end
            if (i > j) begin
                gf2_mul #(.N(4)) inst_gf4_muligej(
                    .AxDI(XxDI[i]),
                    .BxDI(ZxDI[j + i*(i-1)/2]),
                    .QxDO(Xi_mul_Zij[SHARES*i + j])
                );
            end
        end
    end
end


for (i = 0; i < SHARES; i=i+1) begin
    assign Y0xorY1xD[i] = XxDI[i] ^ YxDI[i];
    square_scaler square_scaler_inst (
        .DataInxDI(Y0xorY1xD[i]),
        .DataOutxDO(Y0xorY12xD[i])
    );
    gf2_mul #(.N(4)) inst_gf4_mulbldy(
        .AxDI(/*_XxD[i]*/XxDI_prev[i]),
        .BxDI(SumBlindedYj[i]),
        .QxDO(Xi_mul_SumBlindedYj[i])
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
            // XxDP[k] = XxDI[k];
            for (l = 0; l < SHARES; l=l+1) begin
                FFxDP[SHARES*k + l] = FFxDN[SHARES*k + l];
                ZijBlindedYjDP[SHARES*k + l] = ZijBlindedYjDN[SHARES*k + l];
                // if (k < l) begin
                //     ZijBlindedYjDP[SHARES*k + l] <= YxDI[l] ^ ZxDI[k + l*(l-1)/2];
                // end
                // else if (k > l) begin
                //     ZijBlindedYjDP[SHARES*k + l] <= YxDI[l] ^ ZxDI[l + k*(k-1)/2];
                // end
            end
        end
    // end
end
always @(posedge ClkxCI) begin : proc_XxDP
    integer k;
    for (k = 0; k < SHARES; k=k+1) begin
        XxDP[k] = XxDI[k];
    end
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
            // _XxD[k] = XxDP[k];
            result[k] = 4'b0000;
            SumBlindedYj[k] = 4'b0000;
            for (l = 0; l < SHARES; l=l+1) begin
                if (k!=l) begin
                    SumBlindedYj[k] = SumBlindedYj[k] ^ ZijBlindedYjDP[SHARES*k + l];
                end
                // else 
                if (l > k) begin
                    ZijBlindedYjDN[SHARES*k + l] = YxDI[l] ^ ZxDI[k + l*(l-1)/2];
                    FFxDN[SHARES*k + l] = Xi_mul_Zij[SHARES*k + l] ^ RxDI[k + l*(l-1)/2];  // regular term
                    result[k] = result[k] ^ FFxDP[SHARES*k + l];
                end
                else if (l < k) begin
                    ZijBlindedYjDN[SHARES*k + l] = YxDI[l] ^ ZxDI[l + k*(k-1)/2];
                    FFxDN[SHARES*k + l] = Xi_mul_Zij[SHARES*k + l] ^ RxDI[l + k*(k-1)/2];  // transposed
                    result[k] = result[k] ^ FFxDP[SHARES*k + l];
                end
            end
            result[k] = result[k] ^ Xi_mul_SumBlindedYj[k];
        end
    end
end
if (PIPELINED == 1) begin
    integer k;
    always @(*) begin
        for (k = 0; k < SHARES; k=k+1) begin
            _XxD[k] = XxDP[k];
        end
    end
end

endmodule
