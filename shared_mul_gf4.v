module shared_mul_gf4
#
(
  parameter PIPELINED = 1,
    parameter SHARES = 4
)
(
    ClkxCI,
    RstxBI,
    _XxDI,
    _YxDI,
    _ZxDI,
    _QxDO
);
input ClkxCI;
input RstxBI;


input [4*SHARES-1 : 0] _XxDI;
input [4*SHARES-1 : 0] _YxDI;
input [2*SHARES*(SHARES-1)-1 : 0] _ZxDI;
output [4*SHARES-1 : 0] _QxDO;



wire [3:0] XxDI [SHARES-1 : 0];
wire [3:0] YxDI [SHARES-1 : 0];
wire [3:0] ZxDI [(SHARES*(SHARES-1)/2)-1 : 0];
wire [3:0] QxDO [SHARES-1 : 0];

  for (genvar i = 0; i < SHARES; i=i+1) begin
    for (genvar j = 0; j < 4; j=j+1) begin
        assign XxDI[i][j] = _XxDI[i*4+j];
        assign YxDI[i][j] = _YxDI[i*4+j];
        assign _QxDO[i*4+j] = QxDO[i][j];
      end
  end

  for (genvar i = 0; i < SHARES*(SHARES-1)/2; i=i+1) begin
    for (genvar j = 0; j < 4; j=j+1) begin
        assign ZxDI[i][j] = _ZxDI[i*4+j];
      end
  end

  // Intermediates
  wire [3:0] Xi_mul_Yj [SHARES*SHARES-1:0];
  
  // Synchronization FF's
  reg [3:0] FFxDN     [SHARES*SHARES-1:0];
  reg [3:0] FFxDP     [SHARES*SHARES-1:0];

  // genvar i;
  // genvar j;
  generate
    for (genvar i = 0; i < SHARES; i=i+1) begin
      for (genvar j = 0; j < SHARES; j=j+1) begin
        gf2_mul #(.N(4)) inst_gf4_mul(
          .AxDI(XxDI[i]),
          .BxDI(YxDI[j]),
          .QxDO(Xi_mul_Yj[SHARES*i + j])
          );
      end
    end
  endgenerate

  // purpose: Register process
  // type   : sequential
  // inputs : ClkxCI, RstxBI
  // outputs: 

  // async
  always @(posedge ClkxCI or negedge RstxBI) begin : proc_
    if(~RstxBI) begin
      for (integer i = 0; i < SHARES; i=i+1) begin
        for (integer j = 0; j < SHARES; j=j+1) begin
          FFxDP[SHARES*i + j] <= 4'b0000; 
        end
      end
    end else begin
      for (integer i = 0; i < SHARES; i=i+1) begin
        for (integer j = 0; j < SHARES; j=j+1) begin
          FFxDP[SHARES*i + j] <= FFxDN[SHARES*i + j];
        end
      end
    end
  end

   // wire [1:0] result [SHARES-1:0];
   // // wire[1:0] result;
   //  // k;
   // for (genvar i = 0;i < SHARES; i=i+1) begin
   //   assign result[i] = 2'b00;
   //   for (genvar j = 0; j < SHARES; j=j+1) begin
   //     assign result[i] = result[i] ^ FFxDP[SHARES*i + j];
   //   end
   //   assign QxDO[i] = result[i];
   // end

 reg [3:0] result [SHARES-1:0];
  // wire[1:0] result;
   // k;
 for (genvar i = 0;i < SHARES; i=i+1) begin
   // assign result[i] = 2'b00;
   // for (genvar j = 0; j < SHARES; j=j+1) begin
   //   assign result[i] = result[i] ^ FFxDP[SHARES*i + j];
   // end
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
      always @(FFxDP or FFxDN or Xi_mul_Yj or ZxDI) begin
        for (integer i = 0; i < SHARES; i=i+1) begin
         result[i] = 4'b0000;
          for (integer j = 0; j < SHARES; j=j+1) begin
            if (i==j) begin
              FFxDN[SHARES*i + j] = Xi_mul_Yj[SHARES*i + j];             // domain term
            end
            else if (j > i) begin
              FFxDN[SHARES*i + j] = Xi_mul_Yj[SHARES*i + j] ^ ZxDI[i + j*(j-1)/2];  // regular term
            end
            else  begin
              FFxDN[SHARES*i + j] = Xi_mul_Yj[SHARES*i + j] ^ ZxDI[j + i*(i-1)/2];  // transposed
            end
           result[i] = result[i] ^ FFxDP[SHARES*i + j];
          end
        end

      end

    end
  // endgenerate


endmodule
