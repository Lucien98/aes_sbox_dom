`define RAND_OPT
/*Do not define FV when the sbox is used as a verilog module for masked aes*/
//`define FV

/* You can define only one of PINI and NOIA if using the sbox as 
part of masked aes for the correctness of AES*/
`define PINI
// `define NOIA

function integer _blind_nrnd(input integer d);
begin
if (d==1) _blind_nrnd = 1; // Hack to avoid 0-width signals.
else if (d==2) _blind_nrnd = d/*-1*/;
else _blind_nrnd = d;
end
endfunction

`ifndef PINI
localparam coeff = 11;
`else
localparam coeff = 13;
`endif
