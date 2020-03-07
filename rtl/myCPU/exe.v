`timescale 1ns / 1ps

module exe(                        
     input              EXE_valid,  
    input      [176:0] ID_EXE_bus_r,
    output             EXE_over,    
    output     [164:0] EXE_MEM_bus, 
    input     [ 31:0] decode_pc, 
    input             MEM_allow_in, 

     input             clk,      
     input             resetn,
     output     [  4:0] EXE_wdest,   
     output             execancel

);

    wire multiply;           
    wire division;        
    wire divunsigned;
    wire multunsigned;
    wire mthi;             
    wire mtlo;
    wire [13:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;

 
    wire [4:0] mem_control;  
    wire [31:0] store_data;  
                          

    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;  
    wire       break;
    wire       eret;
    wire       no_inst;
    wire       rf_wen;    
    wire [4:0] rf_wdest;  
    wire        j_valid;
    wire        is_in_delay;
    //pc
    wire [31:0] pc;
    wire        pc_valid;
    assign {division,
            divunsigned,
            multiply,
            mthi,
            mtlo,
            alu_control,
            alu_operand1,
            alu_operand2,
            mem_control,
            store_data,
            mfhi,
            mflo,
            mtc0,
            mfc0,
            cp0r_addr,
            syscall,
            break,
            eret,
            no_inst,
            j_valid,
            pc_valid,
            is_in_delay,
            rf_wen,
            rf_wdest,
            pc          } = ID_EXE_bus_r;

    wire [31:0] alu_result;
    wire overflow_add;
    wire overflow_sub;
    wire overflow_result;
    
    wire lw_valid;
    wire sw_valid;
    wire lh_valid;
    wire sh_valid;
    wire lhw_valid;
    wire load_valid;
    alu alu_module(
        .alu_control  (alu_control ),  
        .alu_src1     (alu_operand1),  
        .alu_src2     (alu_operand2),  
        .alu_result   (alu_result  )  
    );
    assign overflow_add=(alu_operand1[31]&&alu_operand2[31])&&!alu_result[31]||(!alu_operand1[31]&&!alu_operand2[31])&&alu_result[31];
    assign overflow_sub=(alu_operand1[31]&&!alu_operand2[31])&&!alu_result[31]||(!alu_operand1[31]&&alu_operand2[31])&&alu_result[31];
    assign overflow_result=(alu_control[13]&&overflow_add==1)||(alu_control[11]&overflow_sub==1);
    
    assign lw_valid=(mem_control[4]&&mem_control[2]&&alu_result[1:0]!=2'b00);
    assign sw_valid=(mem_control[3]&&mem_control[2]&&alu_result[1:0]!=2'b00);
    assign lh_valid=(mem_control[4]&&mem_control[1]&&alu_result[0]!=1'b0);
    assign sh_valid=(mem_control[3]&&mem_control[1]&&alu_result[0]!=1'b0);
    assign execancel=overflow_result|lw_valid|sw_valid|lh_valid|sh_valid|no_inst;//
    wire        mult_begin; 
    wire [63:0] product; 
    wire        mult_end;
    wire        Unsigned;
    assign Unsigned =divunsigned;
    assign mult_begin = multiply & EXE_valid;
    multiply multiply_module (
        .clk       (clk       ),
        .Unsigned   (Unsigned),
        .mult_begin(mult_begin  ),
        .mult_op1  (alu_operand1), 
        .mult_op2  (alu_operand2),
        .product   (product   ),
        .mult_end  (mult_end  )
    );

    reg wait_380;
    reg MEM_allow_in_r;
    always @(posedge clk)
    begin
        if (execancel && EXE_over&&MEM_allow_in)
        begin
            wait_380 <= 1'b1;
        end
        else if(execancel && EXE_over&&~MEM_allow_in)
        begin
            MEM_allow_in_r <= 1'b1;
        end
        else if(MEM_allow_in_r && MEM_allow_in)
        begin
           wait_380 <= 1'b1;
           MEM_allow_in_r<= 1'b0;
        end
        else if (decode_pc==32'hbfc00380|~resetn)
        begin
           wait_380 <= 1'b0;
        end
    end
    wire        div_begin; 
    wire [63:0] productdiv; 
    wire        div_end;

    assign div_begin = division & EXE_valid;

    division division_module (
        .clk       (clk       ),
        .Unsigned   (Unsigned),
        .div_begin(div_begin),
        .div_op1  (alu_operand1  ), 
        .div_op2  (alu_operand2  ),
        .product   (productdiv   ),
        .div_end  (div_end  )
    );
    assign EXE_over = wait_380?0:EXE_valid & (~multiply | mult_end) & (~division | div_end);
    


    assign EXE_wdest = rf_wdest & {5{EXE_valid}};



    wire [31:0] exe_result;  
    wire [31:0] lo_result;
    wire        hi_write;
    wire        lo_write;


    assign exe_result = mthi     ? alu_operand1 :
                        mtc0     ? alu_operand2 : 
                        multiply ? product[63:32] : 
                        division ? productdiv[63:32] :alu_result;
    assign lo_result  = mtlo ? alu_operand1 : 
                        division ? productdiv[31:0] :product[31:0];
    assign hi_write   = division|multiply | mthi;
    assign lo_write   = division|multiply | mtlo;
    
    assign EXE_MEM_bus = {mem_control,store_data,         
                          exe_result,                    
                          lo_result,                     
                          hi_write,lo_write,             
                          mfhi,mflo,                   
                          mtc0,mfc0,cp0r_addr,syscall,break,eret,no_inst,
                          overflow_result,lw_valid, sw_valid,lh_valid,sh_valid,             
                          j_valid,pc_valid,is_in_delay,
                          rf_wen,rf_wdest,               
                          pc};                           

endmodule
