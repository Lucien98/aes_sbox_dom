input [2*SHARES-1 : 0] _X2xDI;
input [SHARES*(SHARES-1)-1 : 0] _Z2xDI;
output [2*SHARES-1 : 0] _Q2xDO;

wire [1:0] X2xDI [SHARES-1 : 0];
wire [1:0] Z2xDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [1:0] Q2xDO [SHARES-1 : 0];

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign X2xDI[i][j] = _X2xDI[i*2+j];
        assign _Q2xDO[i*2+j] = Q2xDO[i][j];
    end
end

for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign Z2xDI[i][j] = _Z2xDI[i*2+j];
    end
end

// Intermediates
// x *( sum(y+b) ) signal
wire [1:0] X2timesSumBlindedYxD [SHARES-1 : 0];
// x * b signal
wire [1:0] X2timesBxD [SHARES-1 : 0];
wire [2*SHARES-1 : 0] _X2timesBxD;
// X pipelined
reg [1:0] X2xDP [SHARES-1 : 0];
// X input for GF mults => x * (y+z)
reg [1:0] X2pipelinedOrNotxS [SHARES-1 : 0];

// For first-order optimizaion only:
wire [1:0] X2timesYxS [SHARES-1 : 0];
wire [1:0] X2timesBlindedY [SHARES-1 : 0];
// X and Y multiplier inputs depending on pipelinign selection
wire [1:0] X2xD [SHARES-1 : 0];
// X times blinding value B
wire [1:0] X2_times_BxD [SHARES-1 : 0];
wire [1:0] X2_times_B_remaskedxDN [SHARES-1 : 0];
reg [1:0] X2_times_B_remaskedxDP [SHARES-1 : 0];


for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign X2timesBxD[i][j] = _X2timesBxD[i*2+j];
    end
end


// First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin

    // Select inputs for multipliers depending if pipelining is used
    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign X2xD[i][0] = X2xDP[i][0];
            assign X2xD[i][1] = X2xDP[i][1];
        end
    end
    else begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign X2xD[i][0] = X2xDI[i][0];
            assign X2xD[i][1] = X2xDI[i][1];
        end
    end

    // Remask X * B ... + Z
    assign X2_times_B_remaskedxDN[0] = X2_times_BxD[0] ^ Z2xDI[0];
    assign X2_times_B_remaskedxDN[1] = X2_times_BxD[1] ^ Z2xDI[0];

    // Output
    assign Q2xDO[0] = X2timesYxS[0] ^ X2timesBlindedY[0] ^ X2_times_B_remaskedxDP[0];
    assign Q2xDO[1] = X2timesYxS[1] ^ X2timesBlindedY[1] ^ X2_times_B_remaskedxDP[1];


    // Remask multiplication results from different domains
    // process x_times_b_register_p
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            X2_times_B_remaskedxDP[0] = 2'b00;
            X2_times_B_remaskedxDP[1] = 2'b00;
        end
        else begin // rising clock edge
            X2_times_B_remaskedxDP[0] = X2_times_B_remaskedxDN[0];
            X2_times_B_remaskedxDP[1] = X2_times_B_remaskedxDN[1];
        end
    end

    // Multipliers
    for (i = 0; i < SHARES; i = i + 1) begin
        gf2_mul #(.N(2)) x_times_y(
            .AxDI(X2xD[i]),
            .BxDI(YxD[i]),
            .QxDO(X2timesYxS[i])
        );

        gf2_mul #(.N(2)) x_times_blinded_y(
            .AxDI(X2xD[i]),
            .BxDI(BlindedYxDP[i]),
            .QxDO(X2timesBlindedY[i])
        );

        gf2_mul #(.N(2)) x_times_b(
            .AxDI(X2xDI[i]),
            .BxDI(BxDI[0]),
            .QxDO(X2_times_BxD[i])
        );
    end
end



// NO First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 0 || SHARES > 2) begin
    integer k;
    always @(*) begin
        // per share
        for (k = 0; k < SHARES; k = k + 1) begin
            // X input for GF mults => x * (y + z)
            if (PIPELINED == 1) begin
                X2pipelinedOrNotxS[k] = X2xDP[k];
            end
            else begin
                X2pipelinedOrNotxS[k] = X2xDI[k];
            end
        end
    end

    // Generate multipliers calculating x * (sum(y+b))
    for (i = 0; i < SHARES; i = i + 1) begin
            gf2_mul #(.N(2)) gf2_mul(
            .AxDI(X2pipelinedOrNotxS[i]),
            .BxDI(SumBlindedYxD),
            .QxDO(X2timesSumBlindedYxD[i])
        );
    end

    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES)) shared_mul_gf2_1(
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_X2xDI),
        ._YxDI(_BxDI),
        ._ZxDI(_Z2xDI),
        ._QxDO(_X2timesBxD)
    );

    // Output signal x*y = x*(y+b) + x*b
    for (i = 0; i < SHARES; i = i + 1) begin
        assign Q2xDO[i] = X2timesSumBlindedYxD[i] ^ X2timesBxD[i];
    end
end


// General stuff used for all variants:
// Use pipelining --> X needs to be registered
if (PIPELINED == 1) begin
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
    // always @(posedge ClkxCI) begin : proc_
        integer k;
        if (~RstxBI) begin // asynchronous reset (active low)
            for (k = 0; k < SHARES; k = k + 1) begin
                X2xDP[k] = 2'b00;
            end
        end
        else begin // rising clock edge
            for (k = 0; k < SHARES; k = k + 1) begin
                X2xDP[k] = X2xDI[k];
            end
        end
    end
end
