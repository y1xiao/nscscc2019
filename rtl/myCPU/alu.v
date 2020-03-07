`timescale 1ns / 1ps

module alu(
    input  [13:0] alu_control,  
    input  [31:0] alu_src1,     
    input  [31:0] alu_src2,     
    output [31:0] alu_result    
    );


    wire alu_add; 
    wire alu_addu;  
    wire alu_sub;   
    wire alu_subu;  
    wire alu_slt;  
    wire alu_sltu;  
    wire alu_and; 
    wire alu_nor;   
    wire alu_or;   
    wire alu_xor;   
    wire alu_sll;   
    wire alu_srl;   
    wire alu_sra;   
    wire alu_lui;  

    assign {alu_add,
           alu_addu,
           alu_sub,
           alu_subu,
           alu_slt,
           alu_sltu,
           alu_and,
           alu_nor,
           alu_or,
           alu_xor,
           alu_sll,
           alu_srl,
           alu_sra,
           alu_lui}  = alu_control;

    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire [31:0] and_result;
    wire [31:0] nor_result;
    wire [31:0] or_result;
    wire [31:0] xor_result;
    wire [31:0] sll_result;
    wire [31:0] srl_result;
    wire [31:0] sra_result;
    wire [31:0] lui_result;

    assign and_result = alu_src1 & alu_src2;      
    assign or_result  = alu_src1 | alu_src2;      
    assign nor_result = ~or_result;              
    assign xor_result = alu_src1 ^ alu_src2;     
    assign lui_result = {alu_src2[15:0], 16'd0};  


    wire [31:0] adder_op1;
    wire [31:0] adder_op2;
    wire        adder_cin     ;
    wire [31:0] adder_result  ;
    wire        adder_cout    ;
    assign adder_op1 = alu_src1; 
    assign adder_op2 = (alu_add|alu_addu) ? alu_src2 : ~alu_src2; 
    assign adder_cin      = ~(alu_add|alu_addu); 
    assign {adder_cout,adder_result} = adder_op1 + adder_op2 + adder_cin;


    assign slt_result[31:1] = 31'd0;
    assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31]) | (~(alu_src1[31]^alu_src2[31]) & adder_result[31]);


    assign sltu_result = {31'd0, ~adder_cout};

    wire [4:0] shf;
    assign shf = alu_src1[4:0];
    wire [1:0] shf_1_0;
    wire [1:0] shf_3_2;
    assign shf_1_0 = shf[1:0];
    assign shf_3_2 = shf[3:2];
    

    wire [31:0] sll_step1;
    wire [31:0] sll_step2;
    wire [31:0] sll_step3;
    wire [31:0] sll_step4;
    assign sll_step1 = alu_src1[0]?{alu_src2[30:0], 1'd0} : alu_src2   ;              

    assign sll_step2 = alu_src1[1]?{sll_step1[29:0], 2'd0} : sll_step1   ;                

    assign sll_step3 = alu_src1[2]?{sll_step2[27:0], 4'd0} : sll_step2   ;
    assign sll_step4 = alu_src1[3]?{sll_step3[23:0], 8'd0} : sll_step3   ;
    assign sll_result = alu_src1[4]?{sll_step4[15:0], 16'd0} : sll_step4;    


    wire [31:0] srl_step1;
    wire [31:0] srl_step2;
    wire [31:0] srl_step3;
    wire [31:0] srl_step4;
    assign srl_step1 = alu_src1[0]?{1'd0,alu_src2[31:1]} : alu_src2   ;              
                
    assign srl_step2 = alu_src1[1]?{2'd0,srl_step1[31:2]} : srl_step1   ;                
          
    assign srl_step3 = alu_src1[2]?{4'd0,srl_step2[31:4]} : srl_step2   ;
    assign srl_step4 = alu_src1[3]?{8'd0,srl_step3[31:8]} : srl_step3   ;
    assign srl_result = alu_src1[4]?{16'd0,srl_step4[31:16]} : srl_step4;
  
    wire [31:0] sra_step1;
    wire [31:0] sra_step2;
    wire [31:0] sra_step3;
    wire [31:0] sra_step4;
    assign sra_step1 = alu_src1[0]?{alu_src2[31],alu_src2[31:1]} : alu_src2   ;  
    assign sra_step2 = alu_src1[1]?{{2{alu_src2[31]}},sra_step1[31:2]} : sra_step1   ;                   
                  
    assign sra_step3 = alu_src1[2]?{{4{alu_src2[31]}},sra_step2[31:4]} : sra_step2   ;
    assign sra_step4 = alu_src1[3]?{{8{alu_src2[31]}},sra_step3[31:8]} : sra_step3   ;
    assign sra_result = alu_src1[4]?{{16{alu_src2[31]}},sra_step4[31:16]} : sra_step4 ;
    
   
    assign alu_result = (alu_add|alu_sub|alu_addu|alu_subu) ? adder_result[31:0] : 
                        alu_slt           ? slt_result :
                        alu_sltu          ? sltu_result :
                        alu_and           ? and_result :
                        alu_nor           ? nor_result :
                        alu_or            ? or_result  :
                        alu_xor           ? xor_result :
                        alu_sll           ? sll_result :
                        alu_srl           ? srl_result :
                        alu_sra           ? sra_result :
                        alu_lui           ? lui_result :
                        32'd0;
endmodule
