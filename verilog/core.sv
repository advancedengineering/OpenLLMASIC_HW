//core unit with behavior buffer.
import DEFINE_PKG::*;
module core
(
    input clk,
    input rstn,
    input [`ACT_DB_WORDLINE-1:0] act_db_in, //activation from double buffer
    input [`ACT_DB_WORDLINE-1:0] act_in, //activation from other cores
    //kv cache
    input [`KV_ADDR_W-1:0] kv_addr_in,
    input kv_we,
    input kv_me,
    input kv_oe,
    //weight mem
    input [`KV_ADDR_W-1:0] weight_addr_in,
    input weight_we,
    input weight_me,
    input weight_oe,
    //interface RX
    input [`WEIGHT_WORDLINE-1:0] rx_in,
    //input from row buffer
    input [`ROW_BUF_WORDLINE-1:0] row_buf_in,// row buffer shared by a line.

    input [1:0] mac_in_sel,

    input [`MAC_IN_W-1:0] from_core, //input from other cores for weight sharing, group query attention 

    output [`MAC_IN_W-1:0] to_core,

    output [`BIT_W-1:0] quant_out
    


);
KV_CACHE_PACKED kv_entry;
assign kv_entry.me=kv_me;
assign kv_entry.oe=kv_oe;
assign kv_entry.we=kv_we;
memory_model #(DATA_WIDTH=`KV_WORDLINE, ADDR_WIDTH=`KV_ADDR_W) kv_cache (.clk(clk),.address(kv_entry.address),.data(kv_entry.data),.me(kv_entry.me),.we(kv_entry.we),.oe(kv_entry.oe),.data_out(kv_entry.dout));
WEIGHT_MEM_PACKED weight_entry;
assign weight_entry.me=kv_me;
assign weight_entry.oe=kv_oe;
assign weight_entry.we=kv_we;
memory_model #(DATA_WIDTH=`WEIGHT_ADDR_W, ADDR_WIDTH=`WEIGHT_ADDR_W) weight_mem (.clk(clk),.address(weight_entry.address),.data(weight_entry.data),.me(weight_entry.me),.we(weight_entry.we),.oe(weight_entry.oe),.data_out(kv_entry.dout));
// TQ_MEM_PACKED tq_entry;
// memory_model #(DATA_WIDTH=`TK_WORDLINE, ADDR_WIDTH=`TK_ADDR_W) tq_mem (.clk(clk),.address(tq_entry.address),.data(tq_entry.data),.me(tq_entry.me),.we(tq_entry.we),.oe(tq_entry.oe));
// VEC_MEM_PACKED vec_entry;
// memory_model #(DATA_WIDTH=`VEC_WORDLINE, ADDR_WIDTH=`VEC_ADDR_W) vec_mem (.clk(clk),.address(vec_entry.address),.data(vec_entry.data),.me(vec_entry.me),.we(vec_entry.we),.oe(vec_entry.oe));

logic [`ACT_DB_WORDLINE-1:0] act_reg;
logic act_in_sel; //0 from other core, 1 from act double buffer
always_ff @( posedge clk or negedge rstn ) begin
    if(!rstn)
        act_reg<='0;
    else
        act_reg<=act_in_sel?act_db_in:act_in;
end

//value vector collector inside core before storing vector in kv cache wordline
//Assume single MAC unit, so only 1 output at the same time, subject to change.
logic [`WEIGHT_WORDLINE-1:0] value_collector;
logic collect_en;
always_ff @( posedge clk or negedge rstn ) begin
    if(!rstn)
        value_collector<='0;
    else if(collect_en) begin
        value_collector[`BIT_W-1:0]<=quant_out;
        value_collector<=value_collector<<(`BIT_W);
    end
end

//kv cache
logic kv_in_sel;//todo quant_out need registers to collect them
assign kv_entry.data=kv_in_sel?value_collector:row_buf_in; //kv cache input data, 1 for value from quantize output, 0 for key from row buffer
assign kv_entry.addr=kv_addr_in;

//weight mem
assign weight_entry.address=weight_addr_in;
assign weight_entry.data=rx_in;

//mux to choose from kv cache/weight_men/cores
logic [`WEIGHT_WORDLINE-1:0] weight_reg;
logic [`WEIGHT_WORDLINE-1:0] weight_reg_w;
assign to_core=weight_reg;
always_comb begin
    case (mac_in_sel)
        2'b00: weight_reg_w=kv_entry.dout;
        2'b01: weight_reg_w=weight_entry.dout;
        default: weight_reg_w=from_core;
    endcase
end
always_ff @( posedge clk or negedge rstn ) begin
    if(!rstn)
        weight_reg<='0;
    else
        weight_reg<=weight_reg_w;
end

mac_quan mac (.mac_in_weight(weight_reg),.mac_in_act(act_reg),.quant_out(quant_out));//vector size, element bitwidth
endmodule