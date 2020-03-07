`timescale 1ns / 1ps
`define EXC_ENTER_ADDR 32'HBFC00380    
                               
module wb(                     
    input          WB_valid,     

    input  [160:0] MEM_WB_bus_r, 
    output         rf_wen,     
    output [  4:0] rf_wdest,    
    output [ 31:0] rf_wdata,     
    output         WB_over,     

     input             clk,       
    input             resetn,    
       output        exc_valid,
    output [31:0] exc_pc,
     output [  4:0] WB_wdest,     
     output         cancel,       
      output [ 31:0] WB_pc
 
);

    wire [31:0] mem_result;

    wire [31:0] lo_result;
    wire [31:0] exe_result;
    wire        hi_write;
    wire        lo_write;
    
    wire wen;
    wire [4:0] wdest;
    

    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   
    wire      break;
    wire       eret;
    wire       no_inst;
    wire      overflow_result;
    wire      lw_valid;
    wire      sw_valid;
    wire      lh_valid;
    wire      sh_valid;
    wire      j_valid;
    wire      pc_valid;
    wire      time_int;
    wire      is_in_delay;
    wire sw1;
    wire sw0;
    wire sw;
    wire [31:0] pc;    
    assign {wen,
            wdest,
            mem_result,
            lo_result,
            exe_result,
            hi_write,
            lo_write,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            break,
            eret,
            no_inst,
            overflow_result,
            lw_valid,
            sw_valid,
            lh_valid,
            sh_valid,
            j_valid,
            pc_valid,
            is_in_delay,
            pc} = MEM_WB_bus_r;
    reg [31:0] hi;
    reg [31:0] lo;
    
    always @(posedge clk)
    begin
        if (hi_write)
        begin
            hi <= mem_result;
        end
    end
    always @(posedge clk)
    begin
        if (lo_write)
        begin
            lo <= lo_result;
        end
    end
   wire [31:0] cp0r_count;
   reg [31:0] cp0r_badvaddr;
   wire [31:0] cp0r_compare;
   wire wrongaddr;
   wire [31:0] cp0r_status;
   wire [31:0] cp0r_cause;
   
   wire [31:0] cp0r_epc;
   

   wire status_wen;

   wire epc_wen;
   wire count_wen;
   wire compare_wen;
   wire wrongaddrls;
   wire cause_wen;

   assign status_wen = mtc0 & (cp0r_addr=={5'd12,3'd0});
   assign epc_wen    = mtc0 & (cp0r_addr=={5'd14,3'd0});
   assign count_wen    = mtc0 & (cp0r_addr=={5'd9,3'd0});
   assign compare_wen    = mtc0 & (cp0r_addr=={5'd11,3'd0});
   assign cause_wen    = mtc0 & (cp0r_addr=={5'd13,3'd0});
   assign sw1    = cause_wen & mem_result[9];
   assign sw0    = cause_wen & mem_result[8];
   assign sw    = sw1 | sw0;
   assign wrongaddr    =lw_valid|sw_valid|lh_valid|sh_valid|pc_valid;
   assign wrongaddrls =lw_valid|sw_valid|lh_valid|sh_valid;
  

   wire [31:0] cp0r_rdata;
   assign cp0r_rdata = (cp0r_addr=={5'd8,3'd0}) ? cp0r_badvaddr :
                        (cp0r_addr=={5'd9,3'd0}) ? cp0r_count :
                       (cp0r_addr=={5'd11,3'd0}) ? cp0r_compare :
                       (cp0r_addr=={5'd12,3'd0}) ? cp0r_status :
                       (cp0r_addr=={5'd13,3'd0}) ? cp0r_cause  :
                       (cp0r_addr=={5'd14,3'd0}) ? cp0r_epc : 32'd0;
     reg [31:0] epc_r;
   assign cp0r_epc = epc_r;
   always @(posedge clk)
   begin

       if (syscall|break|overflow_result|wrongaddr|no_inst|time_int)
       begin
           epc_r <= (is_in_delay&&~pc_valid)?pc-4:pc;
       end
       else if (sw)
       begin
           epc_r <= pc+4;
       end
       else if (epc_wen)
       begin
           epc_r <= mem_result;
       end
   end
   reg [31:0] compare_r;
   assign cp0r_compare = compare_r;
   always @(posedge clk)
   begin
       if (!resetn)
       begin
           compare_r <= 32'b0;
       end
       else if (compare_wen)
       begin
           compare_r <= mem_result;
       end
   end
   reg [31:0] count_r;

   assign time_int=compare_r!=0&&compare_r==count_r;
   assign cp0r_count = count_r;
   always @(posedge clk)
   begin
       if (!resetn)
       begin
           count_r <= 32'b0;
       end
       else if (count_wen)
       begin
           count_r <= mem_result;
       end
       else 
       begin
           count_r <= count_r+1;
       end
   end

   always @(posedge clk)
   begin
       if (pc_valid)
       begin
           cp0r_badvaddr <= pc;
       end
       else if (wrongaddrls)
       begin
           cp0r_badvaddr <= exe_result;
       end
   end

   reg status_exl_r;
   reg status_ie_r;
   reg [7:0] status_im_r;
   assign cp0r_status = {9'd0,1'd1,6'd0,status_im_r,6'd0,status_exl_r,status_ie_r};

   always @(posedge clk)
   begin
       if (eret|!resetn)
       begin
           status_exl_r <= 1'b0;
           status_ie_r <= 1'b0;
           status_im_r <= 8'b00000000;
       end
       else if (syscall|break|overflow_result|wrongaddr|no_inst|time_int|sw)
       begin
           status_exl_r <= 1'b1;
       end
       else if (status_wen)
       begin
           status_exl_r <= mem_result[1];
           status_ie_r  <= mem_result[0];
           status_im_r  <= mem_result[15:8];
       end
   end
   

   reg [4:0] cause_exc_code_r;
   wire [1:0] ip01;
   reg cause_branch_delay;
   wire  cause_time_int;
   assign ip01={sw1,sw0};
   assign cause_time_int=|compare_r;
   always @(posedge clk)
   begin
       if (syscall|break|overflow_result|lw_valid|sw_valid|lh_valid|sh_valid|no_inst|time_int|sw)
       begin
           cause_branch_delay <= is_in_delay;
       end

    end
   assign cp0r_cause = {cause_branch_delay,cause_time_int,20'd0,ip01,1'd0,cause_exc_code_r,2'd0};
   always @(posedge clk)
   begin
       if (sw)
       begin
           cause_exc_code_r <= 5'd0;
       end
       else if (syscall)
       begin
           cause_exc_code_r <= 5'd8;
       end
       else if(break)
       begin
           cause_exc_code_r <= 5'd9;
       end
       else if(overflow_result)
       begin
           cause_exc_code_r <= 5'hc;
       end
       
       else if(lw_valid|lh_valid|pc_valid)
       begin
           cause_exc_code_r <= 5'h4;
       end
       else if(sw_valid|sh_valid)
       begin
           cause_exc_code_r <= 5'h5;
       end
       else if(no_inst)
       begin
           cause_exc_code_r <= 5'ha;
       end
   end
   

   assign cancel = (syscall|break | eret|overflow_result|wrongaddr|no_inst|time_int|sw) & WB_over;

    assign WB_over = WB_valid;

    assign rf_wen   = (syscall|break | eret|overflow_result|wrongaddr|no_inst|time_int|sw) ? 1'b0 : wen & WB_over;
    assign rf_wdest = wdest;
    assign rf_wdata = mfhi ? hi :
                      mflo ? lo :
                      mfc0 ? cp0r_rdata : mem_result;


    assign exc_valid =  (syscall|break | eret|overflow_result|wrongaddr|no_inst|time_int|sw) & WB_valid;

    assign exc_pc = (syscall|break|overflow_result|wrongaddr|no_inst|time_int|sw) ? `EXC_ENTER_ADDR : cp0r_epc;
    


    assign WB_wdest = rf_wdest & {5{WB_valid}};
    assign WB_pc = pc;
endmodule

