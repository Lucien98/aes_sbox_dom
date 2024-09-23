module real_dom_shared_mul_gf4 #(
    parameter PIPELINED = 1, // 1: yes, 0: no
    parameter FIRST_ORDER_OPTIMIZATION = 1, // 1: yes, 0: no
    parameter SHARES = 2
) (
    ClkxCI,
    RstxBI,
    _XxDI,
    _YxDI,
    _ZxDI,
    _BxDI,
    _QxDO
);
input ClkxCI;
input RstxBI;
input [4*SHARES-1 : 0] _XxDI;
input [4*SHARES-1 : 0] _YxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _ZxDI;
input [4*SHARES-1 : 0] _BxDI;
output [4*SHARES-1 : 0] _QxDO;

wire [3:0] XxDI [SHARES-1 : 0];
wire [3:0] YxDI [SHARES-1 : 0];
wire [3:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [3:0] BxDI [SHARES-1 : 0];
wire [3:0] QxDO [SHARES-1 : 0];

for (genvar i = 0; i < SHARES; i=i+1) begin
    for (genvar j = 0; j < 4; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*4+j];
        assign YxDI[i][j] = _YxDI[i*4+j];
        assign BxDI[i][j] = _BxDI[i*4+j];
        assign _QxDO[i*4+j] = QxDO[i][j];
    end
end

for (genvar i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (genvar j = 0; j < 4; j=j+1) begin
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
wire [3:0] XtimesSumBlindedYxD [SHARES-1 : 0];
// x * b signal
wire [3:0] XtimesBxD [SHARES-1 : 0];
wire [4*SHARES-1 : 0] _XtimesBxD;
// X pipelined
reg [3:0] XxDP [SHARES-1 : 0];
// X input for GF mults => x * (y+z)
reg [3:0] XpipelinedOrNotxS [SHARES-1 : 0];

// For first-order optimizaion only:
wire [3:0] XtimesYxS [SHARES-1 : 0];
wire [3:0] XtimesBlindedY [SHARES-1 : 0];
// Y pipelined
reg [3:0] YxDP [SHARES-1 : 0];
// X and Y multiplier inputs depending on pipelinign selection
wire [3:0] XxD [SHARES-1 : 0];
wire [3:0] YxD [SHARES-1 : 0];
// X times blinding value B
wire [3:0] X_times_BxD [SHARES-1 : 0];
wire [3:0] X_times_B_remaskedxDN [SHARES-1 : 0];
reg [3:0] X_times_B_remaskedxDP [SHARES-1 : 0];


for (genvar i = 0; i < SHARES; i=i+1) begin
    for (genvar j = 0; j < 4; j=j+1) begin
        assign XtimesBxD[i][j] = _XtimesBxD[i*4+j];
    end
end


// First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 1 && SHARES == 2) begin
    // Blinding of Y
    // process blind_y_p

    always @(BxDI or X_times_BxD or XxDI or XxDP or YxDI or YxDP or ZxDI or XtimesYxS or XtimesBlindedY or X_times_B_remaskedxDP) begin
        BlindedYxDN[1] = YxDI[0] ^ BxDI[0];
        BlindedYxDN[0] = YxDI[1] ^ BxDI[0];
    end

    // Select inputs for multipliers depending if pipelining is used
    if (PIPELINED == 1) begin
        for (genvar i = 0; i < SHARES; i = i + 1) begin
            assign XxD[i] = XxDP[i];
            assign YxD[i] = YxDP[i];
        end
    end
    else begin
        for (genvar i = 0; i < SHARES; i = i + 1) begin
            assign XxD[i] = XxDI[i];
            assign YxD[i] = YxDI[i];
        end
    end

    // Remask X * B ... + Z
    assign X_times_B_remaskedxDN[0] = X_times_BxD[0] ^ ZxDI[0];
    assign X_times_B_remaskedxDN[1] = X_times_BxD[1] ^ ZxDI[0];

    // Output
    assign QxDO[0] = XtimesYxS[0] ^ XtimesBlindedY[0] ^ X_times_B_remaskedxDP[0];
    assign QxDO[1] = XtimesYxS[1] ^ XtimesBlindedY[1] ^ X_times_B_remaskedxDP[1];


    // Remask multiplication results from different domains
    // process x_times_b_register_p
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            X_times_B_remaskedxDP[0] <= 4'b0000;
            X_times_B_remaskedxDP[1] <= 4'b0000;
        end
        else begin // rising clock edge
            X_times_B_remaskedxDP[0] <= X_times_B_remaskedxDN[0];
            X_times_B_remaskedxDP[1] <= X_times_B_remaskedxDN[1];
        end
    end

    // Multipliers
    for (genvar i = 0; i < SHARES; i = i + 1) begin
        gf2_mul #(.N(4)) x_times_y(
            .AxDI(XxD[i]),
            .BxDI(YxD[i]),
            .QxDO(XtimesYxS[i])
        );

        gf2_mul #(.N(4)) x_times_blinded_y(
            .AxDI(XxD[i]),
            .BxDI(BlindedYxDP[i]),
            .QxDO(XtimesBlindedY[i])
        );

        gf2_mul #(.N(4)) x_times_b(
            .AxDI(XxDI[i]),
            .BxDI(BxDI[i]),
            .QxDO(X_times_BxD[i])
        );
    end
end



// NO First_order optimized variant
if (FIRST_ORDER_OPTIMIZATION == 0 || SHARES > 2) begin
    reg [3:0] SumBlindedY;
    
    always @(BlindedYxDP or BxDI or XxDI or XxDP or YxDI) begin
        for (integer i = 0; i < SHARES; i = i + 1) begin
            BlindedYxDN[i] = BlindedYxDP[i];
        end
        SumBlindedY = 4'b0000;
        // per share
        for (integer i = 0; i < SHARES; i = i + 1) begin
            BlindedYxDN[i] = YxDI[i] ^ BxDI[i];
            // Sum of blinded Y
            SumBlindedY = SumBlindedY ^ BlindedYxDP[i];
            // X input for GF mults => x * (y + z)
            if (PIPELINED == 1) begin
                XpipelinedOrNotxS[i] = XxDP[i];
            end
            else begin
                XpipelinedOrNotxS[i] = XxDI[i];
            end
        end
        SumBlindedYxD = SumBlindedY;
    end

    // Generate multipliers calculating x * (sum(y+b))
    for (genvar i = 0; i < SHARES; i = i + 1) begin
            gf2_mul #(.N(4)) gf4_mul(
            .AxDI(XpipelinedOrNotxS[i]),
            .BxDI(SumBlindedYxD),
            .QxDO(XtimesSumBlindedYxD[i])
        );
    end

    shared_mul_gf4 #(.PIPELINED(PIPELINED), .SHARES(SHARES)) shared_mul_gf4_1(
        .ClkxCI(ClkxCI),
        .RstxBI(RstxBI),
        ._XxDI(_XxDI),
        ._YxDI(_BxDI),
        ._ZxDI(_ZxDI),
        ._QxDO(_XtimesBxD)
    );

    // Output signal x*y = x*(y+b) + x*b
    for (genvar i = 0; i < SHARES; i = i + 1) begin
        assign QxDO[i] = XtimesSumBlindedYxD[i] ^ XtimesBxD[i];
    end
end


// General stuff used for all variants:
// Use pipelining --> X needs to be registered
if (PIPELINED == 1) begin
    always @(posedge ClkxCI or negedge RstxBI) begin : proc_
        if (~RstxBI) begin // asynchronous reset (active low)
            for (integer i = 0; i < SHARES; i = i + 1) begin
                XxDP[i] = 4'b0000;
                YxDP[i] = 4'b0000;
            end
        end
        else begin // rising clock edge
            for (integer i = 0; i < SHARES; i = i + 1) begin
                XxDP[i] = XxDI[i];
                YxDP[i] = YxDI[i];
            end
        end
    end
end

// Blinding register process
always @(posedge ClkxCI or negedge RstxBI) begin : proc_
    if (~RstxBI) begin // asynchronous reset (active low)
        for (integer i = 0; i < SHARES; i = i + 1) begin
            BlindedYxDP[i] <= 4'b0000;
        end
    end
    else begin // rising clock edge
        for (integer i = 0; i < SHARES; i = i + 1) begin
            BlindedYxDP[i] <= BlindedYxDN[i];
        end
    end
end


    
endmodule