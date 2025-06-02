// 
// Copyright (C) 2025 Feng Zhou
// 
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <https://www.gnu.org/licenses/>.
// 

`define RAND_OPT
// `define PINI
// `define IA
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
            _bcoeff = 6;
        `else
            _bcoeff = 4;
        `endif 
    `else
        `ifndef RAND_OPT
            _bcoeff = 6;
        `else
            _bcoeff = (d <= 3 ? 6 : 4);
        `endif 
    `endif
end
endfunction

function integer _invbcoeff(input integer d);
begin
    `ifndef OPTO1O2
        `ifndef RAND_OPT
            _invbcoeff = 6;
        `else
            _invbcoeff = 4;
        `endif 
    `else
        `ifndef RAND_OPT
            _invbcoeff = (d <= 3 ? 2 : 6);
        `else
            _invbcoeff = (d <= 3 ? 2 : 4);
        `endif 
    `endif
end
endfunction
