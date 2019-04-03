`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Wenchien Ting
// 
// Create Date: 04/02/2019 03:21:56 AM
// Design Name: 
// Module Name: ACC
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`include "scr1_arch_description.svh"

`ifdef SCR1_TCM_EN
module ACC(
    input clk,
    input rst_n,
    //input enable,
    output reg enable,
    input [31:0] addr_in,
    input [31:0] data_in,
    input [31:0] data_mem,
    output reg [31:0] data_out,
    output logic wenb,
    output logic renb,
    output reg [15:2] addr_mem,
    output [3:0] webb_out
    //input [3:0] webb
    );
/* address mapping */
    parameter ACC_MMAP_BASE = 32'hf000_ffff;
    parameter ACC_MMAP_RANG = 32'h0fff_0000;
    //parameter ACC_MMAP_READ_STATUS  =   32'h0000_0000;
    parameter ACC_MMAP_READ_Y       =   32'h0004_0000; // jump 4bytes = 32bits
    parameter ACC_MMAP_WRITE_SRC    =   32'h0008_0000;
    parameter ACC_MMAP_WRITE_DES    =   32'h000c_0000;
    parameter ACC_MMAP_START        =   32'h0010_0000;
    
    
    // Input A
    logic [15:2] A;
    // Input B
    logic [15:2] B;
    // Output Y
    logic [31:0] Y;
    // Signal to start calculation
    logic start;
    // Internal masked  address
    wire [31:0] ACC_addr;
    
    logic [15:0] A_next;
    // Input B
    logic [15:0] B_next;
    // Output Y
    logic [31:0] Y_next;
    assign ACC_addr = (addr_in) & ACC_MMAP_RANG;
    //source and destination address and byte select
    logic word_addr;
    logic byte_sel;
    assign webb_out  = 4'b1111;
    /**
     *    This block handles the MMAP request.
     *
     *    Signal description:
     *    [31:0] addr: MMAP request address
     *    [31:0] wdata:Data write from master
     *    [31:0] rdata:Data read from module
     *  [3:0] wstrb: each bit enables 8-bit write to the 32-bit data
     *  //valid:         MMAP request from master
     *  //ready:         MMAP request is handled
     */
    
    // FSM
    localparam IDLE=2'd0, SRC=2'd1, DES=2'd2, START=2'd3;
    logic [1:0] curr_state;
    logic [1:0] next_state;
    logic [1:0] count;
    logic [1:0] count_next;
    // state reg
    always@(posedge clk or negedge rst_n)begin
      if (~rst_n) begin
                  curr_state <= IDLE;
                  A <= 0;
                  B <= 0;
      end
      else begin
           curr_state <= next_state;
           A <= A_next;
           B <= B_next;
           Y <= Y_next;
    
      end
    end
    // next state logic    
    always@(*)begin
      case (curr_state)
        IDLE    : if (ACC_addr==ACC_MMAP_WRITE_SRC)begin
                    next_state = SRC;
                    A_next = data_in;
                    Y_next = Y;
                   end else 
                    next_state = IDLE;
        SRC     : if (ACC_addr==ACC_MMAP_WRITE_DES)begin
                    next_state = DES;
                    A_next = A;
                    B_next = data_in;
                    Y_next = data_mem;
                  end else 
                    next_state = SRC;
        DES   :   if (ACC_addr==ACC_MMAP_START)begin
                   next_state = START;
                   B_next = B;
                   Y_next = Y;
                  end else     
                   next_state = DES;

        START  : next_state = IDLE;
                  
        default :next_state = IDLE;
      endcase
    end
    
    // output logic
    always@(*)begin
      case (curr_state)

        IDLE    :begin
                  enable = 1'b0;
                  data_out = Y;
                  wenb = 1'b0;
                  renb = 1'b0;
                  end
        SRC     :begin
                  enable = 1'b1;
                  data_out = Y;
                  wenb = 1'b0;
                  renb = 1'b1;
                  addr_mem = A[15:2];
                  end
        DES     : begin
                  enable = 1'b1;
                  wenb = 1'b0;
                  data_out = Y;
                  renb = 1'b0;
                  addr_mem = 14'b0;
                  end
        START   : begin
                  enable = 1'b1;
                  data_out = Y;
                  wenb = 1'b1;
                  renb = 1'b0;
                  addr_mem = B[15:2];
                 end
      endcase
    end       
    
endmodule
`endif // SCR1_TCM_EN
