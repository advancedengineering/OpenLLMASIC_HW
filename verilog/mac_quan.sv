module mac_quan //no pipeline for now.
(
  input [`MAC_IN_W-1:0] mac_in_weight,
  input [`MAC_IN_W-1:0] mac_in_act,
  output [`BIT_W-1:0] quant_out

);
  logic [2*`MAC_IN_W-1:0] mult_out;
  logic [`ADD_TREE_OUT-1:0] quant_in;
  
  genvar i;
  generate
    for(i=0;i<(`MAC_IN_W/`BIT_W);i++)
    begin
      fmul(.a(mac_in_weight[i*`BIT_W:(i*`BIT_W+`BIT_W-1)]),.b([i*`BIT_W:(i*`BIT_W+`BIT_W-1)]),.out(mult_out[i*`BIT_W:(i*`BIT_W+2*`BIT_W-1)]))
    end
  endgenerate

  adder_tree #(2*`BIT_W,$clog2(`N_EMBD/`N_HEAD)) add_tree (.d_in(mult_out),.sum_out(quant_in));

  //todo quant and fmul fadd
endmodule

module adder_tree #(parameter WIDTH=`BIT_W, DEPTH=$clog2(`N_EMBD/`N_HEAD)) 
  (
    input [WIDTH*(2**DEPTH)-1:0] d_in,
    output logic [WIDTH+DEPTH-1:0] sum_out);

  logic [WIDTH-1:0] sums [0:DEPTH-1][0:2**DEPTH];

  genvar i, j;

  generate
    for (i = 0; i < DEPTH; i=i+1) begin : depth
      for (j = 0; j < (2**(DEPTH-i-1))/2; j=j+1) begin : stage
        if(i == 0) begin : first_stage
          fadd #(WIDTH,`EXP_W) adder (.a(d_in[2*WIDTH*j:2*WIDTH*j + WIDTH-1]), .b(d_in[(2*j+1)*WIDTH:(2*j+1)*WIDTH + WIDTH-1]), .sum(sums[i][j]));
        end
        else begin : rest_stages
          fadd #(WIDTH + i,`EXP_W) adder (.a(sums[i-1][2*j]), .b(sums[i-1][2*j+1]), .sum(sums[i][j]));
        end
      end
    end
  endgenerate
  
  assign sum_out = sums[DEPTH-1][0];
endmodule

//assume a,b with same exponent, same bitwidth.
module fadd #(parameter WIDTH=`BIT_W, EXP_WIDTH=`EXP_W)
(
  input [WIDTH-1:0] a,
  input [WIDTH-1:0] b,
  output logic [WIDTH:0] out
);

logic a_sign;
logic a_exponent;
logic [WIDTH-EXP_WIDTH:0] a_mantissa; //extra 1 bit for hidden bit
logic b_sign;
logic b_exponent;
logic [WIDTH-EXP_WIDTH:0] b_mantissa; //extra 1 bit for hidden bit

logic o_sign;
logic o_exponent;
logic o_mantissa;
assign a_sign = a[WIDTH-1];
assign b_sign = b[WIDTH-1];

always_comb begin
  if(a[30:23] == 0) begin //denormalization
    a_exponent = '0;
    a_mantissa = {1'b0, a[WIDTH-EXP_WIDTH-1:0]};
  end else begin
    a_exponent = a[WIDTH-1:WIDTH-EXP_WIDTH];
    a_mantissa = {1'b1, a[WIDTH-EXP_WIDTH-1:0]};
  end
     
  if(b[30:23] == 0) begin //denormalization
    b_exponent = '0;
    b_mantissa = {1'b0, b[22:0]};
  end else begin
    b_exponent = b[WIDTH-1:WIDTH-EXP_WIDTH];
    b_mantissa = {1'b1, b[22:0]};
  end  

  o_exponent = a_exponent;
  if (a_sign == b_sign) begin // Equal signs = add
    o_mantissa = a_mantissa + b_mantissa;
    //Signify to shift
    o_mantissa[24] = 1;
    o_sign = a_sign;
  end else begin // Opposite signs = subtract
    if(a_mantissa > b_mantissa) begin
      o_mantissa = a_mantissa - b_mantissa;
      o_sign = a_sign;
    end else begin
      o_mantissa = b_mantissa - a_mantissa;
      o_sign = b_sign;
    end
  end
end

endmodule

