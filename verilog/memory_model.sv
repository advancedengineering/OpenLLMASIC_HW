import DEFINE_PKG::*;
//todo update
module memory_model
#(parameter DATA_WIDTH = 8;
  parameter ADDR_WIDTH = 8;)
(
input clk, // Clock Input
input [ADDR_WIDTH-1:0] address, // Address Input
input [DATA_WIDTH-1:0] data, // Data in
input me, // memory enable
input we, // Write Enable/Read Enable
input oe,// Output Enable

output logic [DATA_WIDTH-1:0] data_out // Data out
); 

parameter RAM_DEPTH = 1 << ADDR_WIDTH;

logic [DATA_WIDTH-1:0] mem [0:RAM_DEPTH-1];

// Memory Write Block 
// Write Operation : When we = 1, me = 1
always_ff @ (posedge clk)
begin :
   if ( me && we ) begin
       mem[address] <= data;
   end
end

// Memory Read Block 
// Read Operation : When we = 0, oe = 1, me = 1
always_ff @(posedge clk)
begin :
  if (me && !we && oe) begin
    data_out <= mem[address];
  end 
end

endmodule