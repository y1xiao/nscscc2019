`timescale 1ns / 1ps

module mycpu_top(  
    input aclk,    
    input aresetn,  
    input [5:0]int,  
    
   output reg [3:0]arid,
   output [31:0]araddr,
   output [3:0]arlen,
   output [2:0]arsize,
   output [1:0]arburst,
   output [1:0]arlock,
   output [3:0]arcache,
   output [2:0]arprot,
   output arvalid,
   input arready,
   
   input [3:0]rid,
   input [31:0]rdata,
   input [1:0]rresp,
   input rlast,
   input rvalid,
   output reg rready,
   
   output [3:0]awid,
   output [31:0]awaddr,
   output [3:0]awlen,
   output [2:0]awsize,
   output [1:0]awburst,
   output [1:0]awlock,
   output [3:0]awcache,
   output [2:0]awprot,
   output awvalid,
   input awready,
   
   
   
   output [3:0]wid,
   output [31:0]wdata,
   output [3:0]wstrb,
   output wlast,
   output wvalid,
   input  wready,
   
   input  [3:0]bid,
   input  [1:0]bresp,
   input  bvalid,
   output bready,
  
   
   output [31:0]debug_wb_pc,
   output [3:0]debug_wb_rf_wen,
   output [4:0]debug_wb_rf_wnum,
   output [31:0]debug_wb_rf_wdata
   
  
    );

 
    reg IF_valid;
    reg ID_valid;
    reg EXE_valid;
    reg MEM_valid;
    reg WB_valid;

    wire IF_over;
    wire ID_over;
    wire EXE_over;
    wire MEM_over;
    wire WB_over;
 
    wire IF_allow_in;
    wire ID_allow_in;
    wire EXE_allow_in;
    wire MEM_allow_in;
    wire WB_allow_in;
    
    
    wire cancel;    
    wire execancel;
    wire pc_cannel;
    assign IF_allow_in  = (IF_over & ID_allow_in) | cancel;
    assign ID_allow_in  = ~ID_valid  | (ID_over  & EXE_allow_in);
    assign EXE_allow_in = ~EXE_valid | (EXE_over & MEM_allow_in);
    assign MEM_allow_in = ~MEM_valid | (MEM_over & WB_allow_in );
    assign WB_allow_in  = ~WB_valid  | WB_over;
   

   always @(posedge aclk)
    begin
        if (!aresetn)
        begin
            IF_valid <= 1'b0;
        end
        else
        begin
            IF_valid <= 1'b1;
        end
    end
    
    always @(posedge aclk)
    begin
        if (!aresetn || cancel)
        begin
            ID_valid <= 1'b0;
        end
        else if (ID_allow_in)
        begin
            ID_valid <= IF_over;
        end
    end
    
    always @(posedge aclk)
    begin
        if (!aresetn || cancel)
        begin
            EXE_valid <= 1'b0;
        end
        else if (EXE_allow_in)
        begin
            EXE_valid <= ID_over;
        end
    end
    
    always @(posedge aclk)
    begin
        if (!aresetn || cancel)
        begin
            MEM_valid <= 1'b0;
        end
        else if (MEM_allow_in)
        begin
            MEM_valid <= EXE_over;
        end
    end
    
    always @(posedge aclk)
    begin
        if (!aresetn || cancel)
        begin
            WB_valid <= 1'b0;
        end
        else if (WB_allow_in)
        begin
            WB_valid <= MEM_over;
        end
    end
    

    wire [ 64:0] IF_ID_bus;   
    wire [176:0] ID_EXE_bus;  
    wire [164:0] EXE_MEM_bus; 
    wire [160:0] MEM_WB_bus;  
    

    reg [ 64:0] IF_ID_bus_r;
    reg [176:0] ID_EXE_bus_r;
    reg [164:0] EXE_MEM_bus_r;
    reg [160:0] MEM_WB_bus_r;


    always @(posedge aclk)
    begin
        if(IF_over && ID_allow_in)
        begin
            IF_ID_bus_r <= IF_ID_bus;
        end
    end

    always @(posedge aclk)
    begin
        if(ID_over && EXE_allow_in)
        begin
            ID_EXE_bus_r <= ID_EXE_bus;
        end
    end

    always @(posedge aclk)
    begin
        if(EXE_over && MEM_allow_in)
        begin
            EXE_MEM_bus_r <= EXE_MEM_bus;
        end
    end    

    always @(posedge aclk)
    begin
        if(MEM_over && WB_allow_in)
        begin
            MEM_WB_bus_r <= MEM_WB_bus;
        end
    end

   wire  [31:0]  decode_pc;
    wire  jbr_valid;
    wire  [31:0]jbr_pc;
    wire [31:0] inst;
    wire [ 4:0] EXE_wdest;
    wire [ 4:0] MEM_wdest;
    wire [ 4:0] WB_wdest;
    wire [ 3:0] dm_wen;
    wire [31:0] dm_addr;
    wire [31:0] dm_wdata;
    wire [31:0] dm_rdata;
    wire [ 4:0] rs;
    wire [ 4:0] rt;   
    wire [31:0] rs_value;
    wire [31:0] rt_value;
     wire        rf_wen;
    wire [ 4:0] rf_wdest;
    wire [31:0] rf_wdata;    
    

    wire exc_valid;
    wire [31:0]exc_pc;

    wire next_fetch; 


    assign next_fetch = IF_allow_in;
    
    wire [3:0]arid_inst;
    wire [31:0]araddr_inst;
    wire arvalid_inst;
    wire rready_inst;
    
    wire [3:0]arid_load;
    wire [31:0]araddr_load;
    wire arvalid_load;
    wire rready_load;
    reg axirvalid;
    
    wire [3:0]arlen_inst;
    wire [3:0]arlen_load;

    always @(posedge aclk)    
    begin
        if((MEM_over&&arid==4'b1)|(IF_over&&arid==4'b0)|~aresetn)
        begin
           rready<=1'b0;
        end
        else if (axirvalid==1'b1&&arid==4'b0)
        begin
            rready <=rready_inst;
        end
        else if (axirvalid==1'b1&&arid==4'b1)
        begin
            rready <=rready_load;
        end
    end
    always @(posedge aclk)    
    begin
        if(rlast&&rready&&arvalid_inst)
        begin
          axirvalid<=1'b0;
          arid<=arid_inst;

        end
        else if(rlast&&rready&&arvalid_load)
        begin
          axirvalid<=1'b0;
          arid<=arid_load;

        end
        else if((rlast&&rready)|~aresetn)
        begin
          axirvalid<=1'b0;
          arid<=arid_inst;

        end
        else if (axirvalid==1'b0&&arvalid_inst)
        begin

            arid<=arid_inst;
            axirvalid<=1'b1;

        end
        else if (axirvalid==1'b0&&arvalid_load)
        begin

            arid<=arid_load;
            axirvalid<=1'b1;

        end
   
    end

    assign araddr=(axirvalid==1'b0&&arvalid_inst)?araddr_inst:
                (axirvalid==1'b0&&arvalid_load)?araddr_load:
                (axirvalid==1'b1&&arid==4'b0)?  araddr_inst:
                (axirvalid==1'b1&&arid==4'b1)?  araddr_load:32'b0;
    assign arvalid= (axirvalid==1'b1&&arid==4'b0)?  arvalid_inst:
                (axirvalid==1'b1&&arid==4'b1)?  arvalid_load:1'b0;
    assign arlen=
                (axirvalid==1'b1&&arid==4'b0)?  arlen_inst:
                (axirvalid==1'b1&&arid==4'b1)?  arlen_load:4'b0;

    
    fetch IF_module(            
        .clk       (aclk       ), 
        .resetn    (aresetn    ),  
        .IF_valid  (IF_valid  ), 
        .next_fetch(next_fetch), 
        .jbr_valid    (jbr_valid    ), 
        .jbr_pc    (jbr_pc    ), 
        .arbitrate_arid (arid),
        .arid      (arid_inst),
        .arlen      (arlen_inst),
        .rlast      (rlast),
        .araddr    (araddr_inst ),  
        .arvalid_inst   (arvalid_inst),
        .arvalid    (arvalid),
        .arready   (arready),
        .rid       (rid),
        .rdata     (rdata),
        .rvalid    (rvalid),
        .rready    (rready_inst),
        .IF_over   (IF_over   ), 
        .IF_ID_bus (IF_ID_bus ),  
        .pc_cannel (pc_cannel),
        .exc_valid  (exc_valid),
        .exc_pc  (exc_pc)
    );

    decode ID_module(              
        .ID_valid   (ID_valid   ),  
        .IF_ID_bus_r(IF_ID_bus_r),  
        .rs_value   (rs_value   ),  
        .rt_value   (rt_value   ),  
        .rs         (rs         ),  
        .rt         (rt         ),    
        .jbr_valid    (jbr_valid    ),  
        .jbr_pc    (jbr_pc    ),  
        .ID_over    (ID_over    ),  
        .ID_EXE_bus (ID_EXE_bus ),  
        .pc         (decode_pc),
        .clk       (aclk       ),  
        .resetn      (aresetn      ),  
        .IF_over     (IF_over     ),
        .ID_allow_in (ID_allow_in),
        .execancel   (execancel),
        .EXE_wdest   (EXE_wdest   ),
        .MEM_wdest   (MEM_wdest   ),
        .WB_wdest    (WB_wdest    )
        
        
    ); 

    exe EXE_module(                   
        .EXE_valid   (EXE_valid   ),  
        .ID_EXE_bus_r(ID_EXE_bus_r),  
        .EXE_over    (EXE_over    ), 
        .EXE_MEM_bus (EXE_MEM_bus ),  
        .MEM_allow_in (MEM_allow_in ),  
        .clk         (aclk         ), 
        .resetn     (aresetn    ),
        .EXE_wdest   (EXE_wdest),
        .execancel   ( execancel  ),
        
        .decode_pc  (decode_pc)
    );

    mem MEM_module(                  
        .clk          (aclk          ),  
        .resetn       (aresetn),
        .MEM_valid    (MEM_valid    ),  
        .EXE_MEM_bus_r(EXE_MEM_bus_r),  
        .MEM_over     (MEM_over     ),  
        .MEM_WB_bus   (MEM_WB_bus),
        .arbitrate_arid (arid),
        .arid         (arid_load),
        .arlen        (arlen_load),
        .araddr       (araddr_load),
        .arvalid_load      (arvalid_load),
        .arvalid      (arvalid),
        .arready      (arready),
        .rid          (rid),
        .rdata        (rdata),
        .rvalid       (rvalid),
        .rready       (rready_load),
        .awaddr       (awaddr),
        .awsize       (awsize),
        .awvalid       (awvalid),
        .awready       (awready),
        .wdata        (wdata),
        .wstrb        (wstrb),
        .wvalid       (wvalid),
        .wready       (wready),
        .bvalid       (bvalid),
        .bready       (bready),         
        .MEM_allow_in (MEM_allow_in ),  
        .MEM_wdest    (MEM_wdest    ) 
        


    );          
 
    wb WB_module(                     
        .WB_valid    (WB_valid    ),  
        .MEM_WB_bus_r(MEM_WB_bus_r),  
        .rf_wen      (rf_wen      ),  
        .rf_wdest    (rf_wdest    ),  
        .rf_wdata    (rf_wdata    ),  
          .WB_over     (WB_over     ),  
       
        .clk         (aclk         ),  
      .resetn      (aresetn      ),  
          .exc_valid  (exc_valid),
        .exc_pc     (exc_pc),
        .WB_wdest    (WB_wdest    ), 
        .cancel      (cancel      ), 
        

        .WB_pc       (debug_wb_pc       )

    );
    assign arsize=3'b010;
    assign arburst=2'b01;
    assign arlock=0;
    assign arcache=4'b0;
    assign arprot=3'b0;
    assign awid=4'b0001;
    assign awlen=4'b0;
    assign awburst=2'b01;
    assign awlock=0;
    assign awcache=4'b0;
    assign awprot=3'b0;
    assign wid=1;
    assign wlast=1;
  
  

    regfile rf_module(        
        .clk    (aclk      ),  
        .wen    (rf_wen   ),  
        .raddr1 (rs       ),  
        .raddr2 (rt       ),  
        .waddr  (rf_wdest ),  
        .wdata  (rf_wdata ),  
        .rdata1 (rs_value ),  
        .rdata2 (rt_value )  


    );
    assign debug_wb_rf_wnum=rf_wdest;
    assign debug_wb_rf_wdata=rf_wen?rf_wdata:debug_wb_rf_wdata;
     assign debug_wb_rf_wen={4{rf_wen}};
     

endmodule
