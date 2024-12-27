input [2*SHARES-1 : 0] _X4xDI;
input [SHARES*(SHARES-1)-1 : 0] _Z4xDI;
output [2*SHARES-1 : 0] _Q4xDO;

wire [1:0] X4xDI [SHARES-1 : 0];
wire [1:0] Z4xDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [1:0] Q4xDO [SHARES-1 : 0];

for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign X4xDI[i][j] = _X4xDI[i*2+j];
        assign _Q4xDO[i*2+j] = Q4xDO[i][j];
    end
end

for (i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign Z4xDI[i][j] = _Z4xDI[i*2+j];
    end
end

// Intermediates
// x *( sum(y+b) ) signal
wire [1:0] X4timesSumBlindedYxD [SHARES-1 : 0];
// x * b signal
wire [1:0] X4timesBxD [SHARES-1 : 0];
wire [2*SHARES-1 : 0] _X4timesBxD;
// X pipelined
reg [1:0] X4xDP [SHARES-1 : 0];
// X input for GF mults => x * (y+z)
reg [1:0] X4pipelinedOrNotxS [SHARES-1 : 0];

// For first-order optimizaion only:
wire [1:0] X4timesYxS [SHARES-1 : 0];
wire [1:0] X4timesBlindedY [SHARES-1 : 0];
// X and Y multiplier inputs depending on pipelinign selection
wire [1:0] X4xD [SHARES-1 : 0];
// X times blinding value B
wire [1:0] X4_times_BxD [SHARES-1 : 0];
wire [1:0] X4_times_B_remaskedxDN [SHARES-1 : 0];
reg [1:0] X4_times_B_remaskedxDP [SHARES-1 : 0];


for (i = 0; i < SHARES; i=i+1) begin
    for (j = 0; j < 2; j=j+1) begin
        assign X4timesBxD[i][j] = _X4timesBxD[i*2+j];
    end
end


// First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin

    // Select inputs for multipliers depending if pipelining is used
    if (PIPELINED == 1) begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign X4xD[i][0] = X4xDP[i][0];
            assign X4xD[i][1] = X4xDP[i][1];
        end
    end
    else begin
        for (i = 0; i < SHARES; i = i + 1) begin
            assign X4xD[i][0] = X4xDI[i][0];
            assign X4xD[i][1] = X4xDI[i][1];
        end
    end

    // Remask X * B ... + Z
    assign X4_times_B_remaskedxDN[0] = X4_times_BxD[0] ^ Z4xDI[0];
    assign X4_times_B_remaskedxDN[1] = X4_times_BxD[1] ^ Z4xDI[0];

    // Output
    assign Q4xDO[0] = X4timesYxS[0] ^ X4timesBlindedY[0] ^ X4_times_B_remaskedxDP[0];
    assign Q4xDO[1] = X4timesYxS[1] ^ X4timesBlindedY[1] ^ X4_times_B_remaskedxDP[1];


    // Remask multiplication results from different domains
    // process x_times_b_register_p
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            X4_times_B_remaskedxDP[0] = 2'b00;
            X4_times_B_remaskedxDP[1] = 2'b00;
        end
        else begin // rising clock edge
            X4_times_B_remaskedxDP[0] = X4_times_B_remaskedxDN[0];
            X4_times_B_remaskedxDP[1] = X4_times_B_remaskedxDN[1];
        end
    end

    // Multipliers
    for (i = 0; i < SHARES; i = i + 1) begin
        gf2_mul #(.N(2)) x_times_y(
            .AxDI(X4xD[i]),
            .BxDI(YxD[i]),
            .QxDO(X4timesYxS[i])
        );

        gf2_mul #(.N(2)) x_times_blinded_y(
            .AxDI(X4xD[i]),
            .BxDI(BlindedYxDP[i]),
            .QxDO(X4timesBlindedY[i])
        );

        gf2_mul #(.N(2)) x_times_b(
            .AxDI(X4xDI[i]),
            .BxDI(BxDI[0]),
            .QxDO(X4_times_BxD[i])
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
                X4pipelinedOrNotxS[k] = X4xDP[k];
            end
            else begin
                X4pipelinedOrNotxS[k] = X4xDI[k];
            end
        end
    end

    // Generate multipliers calculating x * (sum(y+b))
    for (i = 0; i < SHARES; i = i + 1) begin
            gf2_mul #(.N(2)) gf2_mul(
            .AxDI(X4pipelinedOrNotxS[i]),
            .BxDI(SumBlindedYxD),
            .QxDO(X4timesSumBlindedYxD[i])
        );
    end

    shared_mul_gf2 #(.PIPELINED(PIPELINED), .SHARES(SHARES)) shared_mul_gf2_1(
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_X4xDI),
        ._YxDI(_BxDI),
        ._ZxDI(_Z4xDI),
        ._QxDO(_X4timesBxD)
    );

    // Output signal x*y = x*(y+b) + x*b
    for (i = 0; i < SHARES; i = i + 1) begin
        assign Q4xDO[i] = X4timesSumBlindedYxD[i] ^ X4timesBxD[i];
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
                X4xDP[k] = 2'b00;
            end
        end
        else begin // rising clock edge
            for (k = 0; k < SHARES; k = k + 1) begin
                X4xDP[k] = X4xDI[k];
            end
        end
    end
end
