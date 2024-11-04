module scale
(
    a,
    q
);
input [1:0] a;
output [1:0] q;

generate
    assign q[1] = a[1];
    assign q[0] = a[1] ^ a[0];
endgenerate
    
endmodule