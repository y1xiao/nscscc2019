`timescale 1ns / 1ps

module mem(                         
    input              clk,          
    input              resetn,
    input              MEM_valid,  
    input      [164:0] EXE_MEM_bus_r,

    output             MEM_over,    
     output     [160:0] MEM_WB_bus,   
    
    input      [3:0] arbitrate_arid,
    output     [3:0]arid,
    output [3:0]arlen,
    output     [31:0] araddr, 
    output            arvalid_load,
    input arvalid,
    input             arready,
    input      [3:0]rid,
    input      [31:0]rdata,
    input              rvalid,
    output             rready,
    
    
   output [31:0]awaddr,
   output [2:0]awsize,
   output awvalid,
   input awready,
   output reg [31:0]wdata,
   output reg [3:0]wstrb,
   output wvalid,
   input  wready,
  input  bvalid,
   output bready,
       

   input              MEM_allow_in,
    output     [  4:0] MEM_wdest    

);

   wire [4 :0] mem_control;
   wire [31:0] store_data;   

  wire [31:0] exe_result;
    wire [31:0] lo_result;
   wire        hi_write;
   wire        lo_write;

    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   
    wire       break;
    wire       eret;
    wire       no_inst;
    wire       overflow_result;
     wire       lw_valid;
    wire       sw_valid;
    wire       lh_valid;
    wire       sh_valid; 
    wire       rf_wen;    
    wire [4:0] rf_wdest;  
    wire        j_valid;
    wire        is_in_delay;
    wire [31:0] pc;   
    wire        pc_valid; 
    
    assign arid=1;
    assign arlen=4'b0;
    
    assign {mem_control,
            store_data,
            exe_result,
            lo_result,
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
            rf_wen,
            rf_wdest,
            pc         } = EXE_MEM_bus_r;  

    wire inst_load; 
    wire inst_store; 
    wire ls_word;    
    wire ls_hword;    
    wire lb_sign;   
    assign {inst_load,inst_store,ls_word,ls_hword,lb_sign} = mem_control;


    assign araddr = (exe_result[31:30]==2'b10)?{3'b000,exe_result[28:0]}:exe_result;
    assign awaddr = (exe_result[31:30]==2'b10)?{3'b000,exe_result[28:0]}:exe_result;
    wire wrongaddr;
    assign wrongaddr    =lw_valid|sw_valid|lh_valid|sh_valid;

    always @ (*)    
    begin
        if (MEM_valid && inst_store) 
        begin
            if (wrongaddr)
            begin
                wstrb <= 4'b0000; 
            end
            else if (ls_word)
            begin
                wstrb <= 4'b1111; 
            end
            else if(ls_hword)
            begin
                case (awaddr[1:0])
                    2'b00   : wstrb <= 4'b0011;
             
                    2'b10   : wstrb <= 4'b1100;
              
                    default : wstrb <= 4'b0000;
                endcase
            end
            else
            begin 
                case (awaddr[1:0])
                    2'b00   : wstrb <= 4'b0001;
                    2'b01   : wstrb <= 4'b0010;
                    2'b10   : wstrb <= 4'b0100;
                    2'b11   : wstrb <= 4'b1000;
                    default : wstrb <= 4'b0000;
                endcase
            end
        end
        else
        begin
            wstrb <= 4'b0000;
        end
    end 
    

    always @ (*)  
    begin
        case (awaddr[1:0])
            2'b00   : wdata <= store_data;
            2'b01   : wdata <= {16'd0, store_data[7:0], 8'd0};
            2'b10   : wdata <= {store_data[15:0], 16'd0};
            2'b11   : wdata <= {store_data[7:0], 24'd0};
            default : wdata <= store_data;
        endcase
    end
    

     wire        load_sign;
     wire [31:0] load_result;
     reg [31:0]rdata_temp;
    always @(posedge clk)
    begin
        if (!resetn)
        begin
            rdata_temp <= 32'b0;
        end
        else if(rid==1&&rvalid)
        begin
            rdata_temp <= rdata;
        end
    end
    assign load_sign = ls_hword?(araddr[1:0]==2'd0)?rdata_temp[15]:rdata_temp[31]:
                       (araddr[1:0]==2'd0) ? rdata_temp[ 7] :
                       (araddr[1:0]==2'd1) ? rdata_temp[15] :  
                       (araddr[1:0]==2'd2) ? rdata_temp[23] : rdata_temp[31] ;
     assign load_result[7:0] = (araddr[1:0]==2'd0) ? rdata_temp[ 7:0 ] :
                               (araddr[1:0]==2'd1) ? rdata_temp[15:8 ] :
                               (araddr[1:0]==2'd2) ? rdata_temp[23:16] :
                                                      rdata_temp[31:24] ;
     assign load_result[31:16]= ls_word ? rdata_temp[31:16] :{16{lb_sign & load_sign}};
                           
     assign load_result[15:8]=ls_word?rdata_temp[15:8]:
                              ls_hword?(araddr[1:0]==2'd0)? rdata_temp[15:8 ]:rdata_temp[31:24]:
                              {8{lb_sign & load_sign}};

    wire data_shake;
    assign data_shake=arready&&arvalid;
    reg arvalidr;
    always @(posedge clk)    
    begin

        if (inst_load&&arbitrate_arid!=4'b1&&~MEM_allow_in)
        begin
            arvalidr <= 1'b1; 
        end
        else if ((data_shake&&arbitrate_arid==4'b1)|~resetn)
        begin
            arvalidr <= 1'b0;    

        end
    end
    assign arvalid_load=arvalidr;

    reg rreadyr;
    always @(posedge clk)    
    begin
        if (arready&&arvalid)
        begin
            rreadyr <= 1'b1; 
        end
        else if (MEM_over|~resetn)
        begin 
            rreadyr <= 1'b0;
        end
    end
    assign rready=rreadyr;


   wire awcycle;
    reg awcycler;
    always @(posedge clk)    
    begin
        if (bvalid|~resetn)
        begin
            awcycler <= 1'b1; 
        end
        else if (inst_store&&~MEM_allow_in)
        begin
            awcycler <= 1'b0;    
        end
    end
    assign awcycle=awcycler;

    reg awvalidr;
    always @(posedge clk)    
    begin
        if (inst_store&&~MEM_allow_in&&awcycle)
        begin
            awvalidr <= 1'b1; 
        end
        else if (awready|~resetn)
        begin
            awvalidr <= 1'b0;    
        end
    end
    assign awvalid=awvalidr;
    reg wvalidr;
    always @(posedge clk)    
    begin
        if (awready&&awvalid)
        begin
            wvalidr <= 1'b1; 
        end
        else if (wready)
        begin  
            wvalidr <= 1'b0;
        end
    end
    assign wvalid=wvalidr;
    reg breadyr;
    always @(posedge clk)    
    begin
        if (awready)
        begin
            breadyr <= 1'b1; 
        end
        else if (bvalid)
        begin  
            breadyr <= 1'b0;
        end
    end
    assign bready=breadyr;
    
    
    
    reg men_overr;
    always @(posedge clk)
    begin
        if (MEM_allow_in|~resetn)
        begin
            men_overr <= 1'b0;
        end
        else if(rid==1&&rvalid&&inst_load)
        begin
            men_overr <= 1'b1;
        end
        else if(bvalid&&inst_store)
        begin
            men_overr <= 1'b1;
        end
    end
    assign MEM_over = (inst_load|inst_store)?men_overr:MEM_valid;

    assign MEM_wdest = rf_wdest & {5{MEM_valid}};


    wire [31:0] mem_result; 
    assign mem_result = inst_load ? load_result : exe_result;
    
    assign MEM_WB_bus = {rf_wen,rf_wdest,                  
                         mem_result,                        
                         lo_result,                        
                         exe_result,
                         hi_write,lo_write,             
                         mfhi,mflo,                    
                         mtc0,mfc0,cp0r_addr,syscall,break,eret,no_inst,  
                         overflow_result,lw_valid,sw_valid,lh_valid,sh_valid,
                         j_valid,pc_valid,is_in_delay,
                         pc};                               

endmodule

