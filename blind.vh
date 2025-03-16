`define RAND_OPT
// `define PINI
// `define NOIA
// `define FV
`define OPTO1O2

function integer _blind_nrnd(input integer d);
begin
if (d==1) _blind_nrnd = 1; // Hack to avoid 0-width signals.
else if (d==2) _blind_nrnd = d-1;
else _blind_nrnd = d;
end
endfunction

function integer _bcoeff(input integer d);
begin
    `ifndef OPTO1O2
        `ifndef RAND_OPT
            _bcoeff = 4;
        `else
            _bcoeff = 2;
        `endif 
    `else
        `ifndef RAND_OPT
            _bcoeff = 4;
        `else
            _bcoeff = (d <= 3 ? 4 : 2);
        `endif 
    `endif
end
endfunction

`ifndef OPTO1O2
    `ifndef RAND_OPT
        localparam invbcoeff = 4;
    `else
        localparam invbcoeff = 2;
    `endif 
`else
    `ifndef RAND_OPT
        localparam invbcoeff = (d <= 3 ? 2 : 4);
    `else
        localparam invbcoeff = 2;
    `endif 
`endif
