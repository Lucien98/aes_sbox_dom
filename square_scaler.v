// 
// Copyright (C) 2025 Feng Zhou, Gehui Yang
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

module square_scaler
(
    DataInxDI,
    DataOutxDO
);
input [3:0] DataInxDI;
output [3:0] DataOutxDO;

generate
    assign DataOutxDO[3] = DataInxDI[0] ^ DataInxDI[2];
    assign DataOutxDO[2] = DataInxDI[1] ^ DataInxDI[3];
    assign DataOutxDO[1] = DataInxDI[1] ^ DataInxDI[0];
    assign DataOutxDO[0] = DataInxDI[0];
endgenerate
    
endmodule