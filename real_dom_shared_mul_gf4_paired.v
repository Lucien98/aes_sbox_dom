module real_dom_shared_mul_gf4_paired #(
    parameter PIPELINED = 1, // 1: yes, 0: no
    parameter FIRST_ORDER_OPTIMIZATION = 1, // 1: yes, 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    RstxBI,
    _X1xDI,
    _X2xDI,
    _YxDI,
    _ZxDI,
    _BxDI,
    _Q1xDO,
    _Q2xDO
);

`include "blind.vh"
localparam blind_n_rnd = _blind_nrnd(SHARES);

input ClkxCI;
input RstxBI;
input [4*SHARES-1 : 0] _X1xDI;
input [4*SHARES-1 : 0] _X2xDI;
input [4*SHARES-1 : 0] _YxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _ZxDI;
input [4*blind_n_rnd-1 : 0] _BxDI;
output [4*SHARES-1 : 0] _Q1xDO;
output [4*SHARES-1 : 0] _Q2xDO;

wire [3:0] X1xDI [SHARES-1 : 0];
wire [3:0] X2xDI [SHARES-1 : 0];
wire [3:0] YxDI [SHARES-1 : 0];
wire [3:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [3:0] BxDI [blind_n_rnd-1 : 0];
wire [3:0] Q1xDO [SHARES-1 : 0];
wire [3:0] Q2xDO [SHARES-1 : 0];

genvar i;
genvar j;
for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign X1xDI[i][j] = _X1xDI[i*4+j];
        assign X2xDI[i][j] = _X2xDI[i*4+j];
        assign YxDI[i][j] = _YxDI[i*4+j];
        // assign BxDI[i][j] = _BxDI[i*4+j];
        assign _Q1xDO[i*4+j] = Q1xDO[i][j];
        assign _Q2xDO[i*4+j] = Q2xDO[i][j];
    end
end

if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin
    for (i = 0; i < SHARES-1; i=i+1) begin
        for (j = 0; j < 4; j=j+1) begin
            assign BxDI[i][j] = _BxDI[i*2+j];
        end
    end
end
else begin
    for (i = 0; i < SHARES; i=i+1) begin
        for (j = 0; j < 4; j=j+1) begin
            assign BxDI[i][j] = _BxDI[i*4+j];
        end
    end    
end


for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign ZxDI[i][j] = _ZxDI[i*4+j];
    end
end

// Intermediates
// Blinded Y values
reg [3:0] BlindedYxDN [SHARES-1 : 0];
reg [3:0] BlindedYxDP [SHARES-1 : 0];
// Sum of blinded Y shares
reg [3:0] SumBlindedYxD;
// x *( sum(y+b) ) signal
wire [3:0] X1timesSumBlindedYxD [SHARES-1 : 0];
wire [3:0] X2timesSumBlindedYxD [SHARES-1 : 0];
// x * b signal
wire [3:0] X1timesBxD [SHARES-1 : 0];
wire [3:0] X2timesBxD [SHARES-1 : 0];
wire [4*SHARES-1 : 0] _X1timesBxD;
wire [4*SHARES-1 : 0] _X2timesBxD;
// X pipelined
reg [3:0] X1xDP [SHARES-1 : 0];
reg [3:0] X2xDP [SHARES-1 : 0];
// X input for GF mults => x * (y+z)
reg [3:0] X1pipelinedOrNotxS [SHARES-1 : 0];
reg [3:0] X2pipelinedOrNotxS [SHARES-1 : 0];

// For first-order optimizaion only:
wire [3:0] X1timesYxS [SHARES-1 : 0];
wire [3:0] X1timesBlindedY [SHARES-1 : 0];
wire [3:0] X2timesYxS [SHARES-1 : 0];
wire [3:0] X2timesBlindedY [SHARES-1 : 0];
// Y pipelined
reg [3:0] YxDP [SHARES-1 : 0];
// X and Y multiplier inputs depending on pipelinign selection
wire [3:0] X1xD [SHARES-1 : 0];
wire [3:0] X2xD [SHARES-1 : 0];
wire [3:0] YxD [SHARES-1 : 0];
// X times blinding value B
wire [3:0] X1_times_BxD [SHARES-1 : 0];
wire [3:0] X1_times_B_remaskedxDN [SHARES-1 : 0];
reg [3:0] X1_times_B_remaskedxDP [SHARES-1 : 0];

wire [3:0] X2_times_BxD [SHARES-1 : 0];
wire [3:0] X2_times_B_remaskedxDN [SHARES-1 : 0];
reg [3:0] X2_times_B_remaskedxDP [SHARES-1 : 0];


for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 4; j=j+1) begin
        assign X1timesBxD[i][j] = _X1timesBxD[i*4+j];
        assign X2timesBxD[i][j] = _X2timesBxD[i*4+j];
    end
end


// First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin
    // Blinding of Y
    // process blind_y_p

    //always @(BxDI or X_times_BxD or X1xDI or X1xDP or YxDI or YxDP or ZxDI or XtimesYxS or XtimesBlindedY or X_times_B_remaskedxDP) begin
    always @(*) begin
        BlindedYxDN[1] = YxDI[0] ^ BxDI[0];
        BlindedYxDN[0] = YxDI[1] ^ BxDI[0];
    end

    // Select inputs for multipliers depending if pipelining is used
    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign X1xD[i] = X1xDP[i];
            assign X2xD[i] = X2xDP[i];
            assign YxD[i] = YxDP[i];
        end
    end
    else begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign X1xD[i] = X1xDI[i];
            assign X2xD[i] = X2xDI[i];
            assign YxD[i] = YxDI[i];
        end
    end

    // Remask X * B ... + Z
    assign X1_times_B_remaskedxDN[0] = X1_times_BxD[0] ^ ZxDI[0];
    assign X1_times_B_remaskedxDN[1] = X1_times_BxD[1] ^ ZxDI[0];

    assign X2_times_B_remaskedxDN[0] = X2_times_BxD[0] ^ ZxDI[0];
    assign X2_times_B_remaskedxDN[1] = X2_times_BxD[1] ^ ZxDI[0];

    // Output
    assign Q1xDO[0] = X1timesYxS[0] ^ X1timesBlindedY[0] ^ X1_times_B_remaskedxDP[0];
    assign Q1xDO[1] = X1timesYxS[1] ^ X1timesBlindedY[1] ^ X1_times_B_remaskedxDP[1];
    assign Q2xDO[0] = X2timesYxS[0] ^ X2timesBlindedY[0] ^ X2_times_B_remaskedxDP[0];
    assign Q2xDO[1] = X2timesYxS[1] ^ X2timesBlindedY[1] ^ X2_times_B_remaskedxDP[1];


    // Remask multiplication results from different domains
    // process x_times_b_register_p
    always @(posedge ClkxCI or negedge RstxBI) begin : proc1_
    // always @(posedge ClkxCI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            X1_times_B_remaskedxDP[0] <= 4'b0000;
            X1_times_B_remaskedxDP[1] <= 4'b0000;
            X2_times_B_remaskedxDP[0] <= 4'b0000;
            X2_times_B_remaskedxDP[1] <= 4'b0000;
        end
        else begin // rising clock edge
            X1_times_B_remaskedxDP[0] <= X1_times_B_remaskedxDN[0];
            X1_times_B_remaskedxDP[1] <= X1_times_B_remaskedxDN[1];
            X2_times_B_remaskedxDP[0] <= X2_times_B_remaskedxDN[0];
            X2_times_B_remaskedxDP[1] <= X2_times_B_remaskedxDN[1];
        end
    end

    // Multipliers
    // the first instance
    for (i = 0; i < SHARES; i = i + 1) begin
        gf2_mul #(.N(4)) x1_times_y(
            .AxDI(X1xD[i]),
            .BxDI(YxD[i]),
            .QxDO(X1timesYxS[i])
        );

        gf2_mul #(.N(4)) x1_times_blinded_y(
            .AxDI(X1xD[i]),
            .BxDI(BlindedYxDP[i]),
            .QxDO(X1timesBlindedY[i])
        );

        gf2_mul #(.N(4)) x1_times_b(
            .AxDI(X1xDI[i]),
            .BxDI(BxDI[0]),
            .QxDO(X1_times_BxD[i])
        );
    end
    // the second instance
    for (i = 0; i < SHARES; i = i + 1) begin
        gf2_mul #(.N(4)) x2_times_y(
            .AxDI(X2xD[i]),
            .BxDI(YxD[i]),
            .QxDO(X2timesYxS[i])
        );

        gf2_mul #(.N(4)) x2_times_blinded_y(
            .AxDI(X2xD[i]),
            .BxDI(BlindedYxDP[i]),
            .QxDO(X2timesBlindedY[i])
        );

        gf2_mul #(.N(4)) x2_times_b(
            .AxDI(X2xDI[i]),
            .BxDI(BxDI[0]),
            .QxDO(X2_times_BxD[i])
        );
    end
end



// NO First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 0 || SHARES > 2) begin
    reg [3:0] SumBlindedY;
    integer k;
    
    //always @(BlindedYxDP or BxDI or X1xDI or X1xDP or YxDI) begin
    always @(*) begin
        for (k = 0; k < SHARES; k = k + 1) begin
            BlindedYxDN[k] = BlindedYxDP[k];
        end
        SumBlindedY = 4'b0000;
        // per share
        for (k = 0; k < SHARES; k = k + 1) begin
            BlindedYxDN[k] = YxDI[k] ^ BxDI[k];
            // Sum of blinded Y
            SumBlindedY = SumBlindedY ^ BlindedYxDP[k];
            // X input for GF mults => x * (y + z)
            if (PIPELINED == 1) begin
                X1pipelinedOrNotxS[k] = X1xDP[k];
                X2pipelinedOrNotxS[k] = X2xDP[k];
            end
            else begin
                X1pipelinedOrNotxS[k] = X1xDI[k];
                X2pipelinedOrNotxS[k] = X2xDI[k];
            end
        end
        SumBlindedYxD = SumBlindedY;
    end

    // Generate multipliers calculating x * (sum(y+b))
    for (i = 0; i < SHARES; i = i + 1) begin
            gf2_mul #(.N(4)) gf4_mul_1(
            .AxDI(X1pipelinedOrNotxS[i]),
            .BxDI(SumBlindedYxD),
            .QxDO(X1timesSumBlindedYxD[i])
        );
    end

    for (i = 0; i < SHARES; i = i + 1) begin
            gf2_mul #(.N(4)) gf4_mul_2(
            .AxDI(X2pipelinedOrNotxS[i]),
            .BxDI(SumBlindedYxD),
            .QxDO(X2timesSumBlindedYxD[i])
        );
    end

    shared_mul_gf4 #(.PIPELINED(PIPELINED), .SHARES(SHARES)) shared_mul_gf4_1(
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_X1xDI),
        ._YxDI(_BxDI),
        ._ZxDI(_ZxDI),
        ._QxDO(_X1timesBxD)
    );

    shared_mul_gf4 #(.PIPELINED(PIPELINED), .SHARES(SHARES)) shared_mul_gf4_2(
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_X2xDI),
        ._YxDI(_BxDI),
        ._ZxDI(_ZxDI),
        ._QxDO(_X2timesBxD)
    );

    // Output signal x*y = x*(y+b) + x*b
    for (i = 0; i < SHARES; i = i + 1) begin
        assign Q1xDO[i] = X1timesSumBlindedYxD[i] ^ X1timesBxD[i];
        assign Q2xDO[i] = X2timesSumBlindedYxD[i] ^ X2timesBxD[i];
    end
end


// General stuff used for all variants:
// Use pipelining --> X needs to be registered
if (PIPELINED == 1) begin
    integer k;
    always @(posedge ClkxCI or negedge RstxBI) begin : proc2_
    // always @(posedge ClkxCI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            for (k = 0; k < SHARES; k = k + 1) begin
                X1xDP[k] = 4'b0000;
                X2xDP[k] = 4'b0000;
                YxDP[k] = 4'b0000;
            end
        end
        else begin // rising clock edge
            for (k = 0; k < SHARES; k = k + 1) begin
                X1xDP[k] = X1xDI[k];
                X2xDP[k] = X2xDI[k];
                YxDP[k] = YxDI[k];
            end
        end
    end
end

// Blinding register process
always @(posedge ClkxCI or negedge RstxBI) begin : proc3_
// always @(posedge ClkxCI) begin : proc_
    integer k;
    if (~RstxBI) begin // asynchronous reset (active low)
        for (k = 0; k < SHARES; k = k + 1) begin
            BlindedYxDP[k] <= 4'b0000;
        end
    end
    else begin // rising clock edge
        for (k = 0; k < SHARES; k = k + 1) begin
            BlindedYxDP[k] <= BlindedYxDN[k];
        end
    end
end


    
endmodule