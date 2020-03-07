`timescale 1ns / 1ps

`define STARTADDR 32'Hbfc00000   
module fetch(                    
    input             clk,      
    input             resetn,    
    input             IF_valid,  
    input             next_fetch,     
    input     jbr_valid,
    input     [31:0]jbr_pc,    
    input      [3:0]  arbitrate_arid,
    output     [3:0]  arid,
    output     [3:0]arlen,
    output     [31:0] araddr, 
    output            arvalid_inst,
    input            arvalid,
    input             arready,
    input      [3:0]rid,
    
    input      [31:0]rdata,
    input              rvalid,
    output             rready,
    input              rlast,
    output reg        IF_over,   
    output     [64:0] IF_ID_bus, 
    output            pc_cannel,
    input        exc_valid,
    input [31:0] exc_pc
);

    wire [31:0] next_pc;
    wire [31:0] seq_pc;
    reg  [31:0] pc;
    
    
   
    assign arid = 4'b0000;
    assign arlen=4'b1111;

    reg  [1:0]nextrvalid;
    reg  reading;

    wire    pc_valid;
    wire   addr_shake;
    assign addr_shake=arready&&arvalid;
    always @(posedge clk)   
    begin
        if (!resetn)
        begin
            nextrvalid <= 2'b0; 
        end
        else if(addr_shake&&arbitrate_arid==4'b0&&rlast&&rid==4'b0)
        begin
            nextrvalid <= 2'b1;
        end
        else if(addr_shake&&arbitrate_arid==4'b0)
        begin
            nextrvalid <= nextrvalid+1;
        end
        else if (rlast&&rid==4'b0)
        begin
            nextrvalid <= nextrvalid-1;    
        end
    end

    assign seq_pc[31:2]    = pc[31:2] + 1'b1;  
    assign seq_pc[1:0]     = pc[1:0];

    assign next_pc = exc_valid ? exc_pc : 
                     jbr_valid ? jbr_pc : seq_pc;
    assign pc_valid = (pc[1:0]!=2'b00);
    assign pc_cannel = pc_valid;
    always @(posedge clk)    
    begin
        if (!resetn)
        begin
            pc <= `STARTADDR; 
            
        end
        else if (next_fetch)
        begin
            pc <= next_pc;    
        end
    end
    reg wen_cache;
    wire en_cache;
    reg [31:0]wdata_cache;
    wire [31:0]rdata_cache;
    wire [8:0]addr_cache;
    wire cache_in;
    reg  [25:0]tag;
    reg  [5:0]burst_num;
    assign en_cache=1;
    blk_mem_gen_0 blk_mem_gen_0(
        .clka  (clk           ),
        .wea   (wen_cache           ),
        .ena   (en_cache     ),
        .dina  (wdata_cache         ),
        .douta (rdata_cache         ),
        .addra (addr_cache     )
    );
    assign cache_in = ~|(tag^pc[31:6]);
    assign addr_cache=cache_in?{pc[5:0],3'b0}:{burst_num-4,3'b0};
    always @(posedge clk)    
    begin
        if (!resetn)
        begin
            tag <= 26'b0; 
        end
        else if(next_fetch)
        begin
            tag <= pc[31:6];
        end
    end
    reg arvalidr;
    always @(posedge clk)   
    begin
        if (!resetn|next_fetch)
        begin
            arvalidr <= 1'b1; 
        end
        else if (addr_shake&&arbitrate_arid==4'b0|~arvalid_inst)
        begin
            arvalidr <= 1'b0;    
        end
    end
    assign arvalid_inst=(cache_in|pc_valid)?1'b0:arvalidr;
//
//读请求数据握手
    reg rreadyr;
    always @(posedge clk)    
    begin
        if (addr_shake)
        begin
            rreadyr <= 1'b1; 
        end
        else if (IF_over|~resetn)
        begin 
            rreadyr <= 1'b0;
        end
    end
    assign rready=rreadyr;

    assign araddr = {pc[31:6],6'b0};


    always @(posedge clk)
    begin
        if (!resetn || next_fetch)
        begin
            IF_over <= 1'b0;
            burst_num <= 6'b0;
            wen_cache <=1'b0;
        end
        else if(cache_in|pc_valid)
        begin
            IF_over <= IF_valid;
        end
        else if(rid==0&&rlast&&nextrvalid==2'b01&&~addr_shake)
        begin
            IF_over <= IF_valid;
            wen_cache <= 1'b1;
            burst_num <=burst_num+4;
            wdata_cache <=rdata;
        end
        else if(rid==0&&rvalid&&nextrvalid==2'b01&&~addr_shake)
        begin
            wen_cache <= 1'b1;
            burst_num <=burst_num+4;
            wdata_cache <=rdata;
        end
        else 
        begin
            wen_cache <=1'b0;
        end
    end
    reg [31:0]inst_temp;
    always @(posedge clk)
    begin
        if (!resetn)
        begin
            inst_temp <= 32'b0;
        end
        else if(rvalid&&rid==4'b0&&(burst_num==pc[5:0]))
        begin
            inst_temp <= rdata;
        end
    end
        wire [31:0]inst;
        assign inst=pc_valid?32'b0:cache_in?rdata_cache:inst_temp;
    assign IF_ID_bus = {pc, inst,pc_valid};  

endmodule