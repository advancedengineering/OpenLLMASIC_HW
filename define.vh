`ifndef _DEFINE_SVH_
`define _DEFINE_SVH_ 
package DEFINE_PKG;

//fpu
`define DIMENSION 4
`define M_W     3   
`define EXP_W   4
`define BIT_W   8
`define MULT_W  `M_W+`M_W+2
`define EXP_MAX  2**(`EXP_W-1)+2**(`EXP_W)-3

//core
//given n_head and n_embd, MAC unt needs n_embd/n_head multiplications
//kv cache, weight mem, act reg wordline should be n_embd/n_head*bit_w 
`define N_HEAD 16
`define N_EMBD 256
`define KV_WORDLINE `N_EMBD/`N_HEAD*`BIT_W
`define KV_ADDR_W
typedef struct packed{
    logic [`KV_ADDR_W-1:0] address; // Address Input
    logic [`KV_WORDLINE-1:0] data; 
    logic me; // memory enable
    logic we; // Write Enable/Read Enable
    logic oe;// Output Enable
    logic [`KV_WORDLINE-1:0] dout;
} KV_CACHE_PACKED;
`define WEIGHT_WORDLINE `N_EMBD/`N_HEAD*`BIT_W
`define WEIGHT_ADDR_W 
typedef struct packed{
    logic [`WEIGHT_ADDR_W-1:0] address; // Address Input
    logic [`WEIGHT_WORDLINE-1:0] data; 
    logic me; // memory enable
    logic we; // Write Enable/Read Enable
    logic oe;// Output Enable
    logic [`WEIGHT_WORDLINE-1:0] dout;
} WEIGHT_MEM_PACKED;
`define MAC_IN_W `N_EMBD/`N_HEAD*`BIT_W
`define ADD_TREE_OUT `BIT_W+$clog2(`N_EMBD/`N_HEAD)-1

//row buffer
`define ACT_DB_WORDLINE `N_EMBD/`N_HEAD*`BIT_W
`define ACT_DB_ADDR_W

`define TK_WORDLINE
`define TK_ADDR_W 
typedef struct packed{
    logic [`TK_WORDLINE-1:0] address; // Address Input
    logic [`TK_ADDR_W-1:0] data; 
    logic me; // memory enable
    logic we; // Write Enable/Read Enable
    logic oe;// Output Enable
} TQ_MEM_PACKED;
`define VEC_WORDLINE
`define VEC_ADDR_W 
typedef struct packed{
    logic [`VEC_WORDLINE-1:0] address; // Address Input
    logic [`VEC_ADDR_W-1:0] data; 
    logic me; // memory enable
    logic we; // Write Enable/Read Enable
    logic oe;// Output Enable
} VEC_MEM_PACKED;
`define ROW_BUF_WORDLINE


endpackage
`endif
