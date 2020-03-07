`timescale 1ns / 1ps
module decode(                    
    input              ID_valid,   
    input      [ 64:0] IF_ID_bus_r, 
    input      [ 31:0] rs_value,    
    input      [ 31:0] rt_value,    
    output     [  4:0] rs,         
    output     [  4:0] rt,         
    output     jbr_valid,
    output     [31:0]jbr_pc,
    output             ID_over,   
    output     [176:0] ID_EXE_bus,  
    output     [ 31:0] pc, 
    input               clk,
    input               resetn,
    input              IF_over,     
    input              ID_allow_in,
    input              execancel,
    input      [  4:0] EXE_wdest,   
    input      [  4:0] MEM_wdest,  
    input      [  4:0] WB_wdest    
    
);
    wire [31:0] inst;
    wire        pc_valid;
    assign {pc, inst,pc_valid} = IF_ID_bus_r; 
    wire [5:0] op;       
    wire [4:0] rd;       
    wire [4:0] sa;      
    wire [5:0] funct;    
    wire [15:0] imm;     
    wire [15:0] offset;  
    wire [25:0] target;  
    wire [2:0] cp0r_sel;
    wire [57:0]inst_result;
    assign op     = inst[31:26];  
    assign rs     = inst[25:21];  
    assign rt     = inst[20:16]; 
    assign rd     = inst[15:11];  
    assign sa     = inst[10:6];   
    assign funct  = inst[5:0];    
    assign imm    = inst[15:0];   
    assign offset = inst[15:0];   
    assign target = inst[25:0];   
    assign cp0r_sel= inst[2:0];   

    
     inst_type inst_type (
        .f_inst    (inst),
        .op       (inst[31:26]),
        .rd   (inst[15:11]),
        .sa(inst[10:6]  ),
        .funct  (inst[5:0]), 
        .rt  (inst[20:16]),
        .rs   (inst[25:21]   ),
        .i_type  (inst_result  )
    );
    
    
    
    
    wire i_ADD;
    wire i_SUB;
    wire i_ADDI;
    wire i_DIV;
    wire i_DIVU;
    wire i_MULTU;
    
    wire i_SH;
    wire i_LH;
    wire i_LHU;
    wire i_BLTZAL;
    wire i_BGEZAL;
    wire i_BREAK;
    wire i_nop;
    
    wire i_ADDU, i_SUBU , i_SLT , i_AND;
    wire i_NOR , i_OR   , i_XOR , i_SLL;
    wire i_SRL , i_ADDIU, i_BEQ , i_BNE;
    wire i_LW  , i_SW   , i_LUI , i_J;
    wire i_SLTU, i_JALR , i_JR  , i_SLLV;
    wire i_SRA , i_SRAV , i_SRLV, i_SLTIU;
    wire i_SLTI, i_BGEZ , i_BGTZ, i_BLEZ;
    wire i_BLTZ, i_LB   , i_LBU , i_SB;
    wire i_ANDI, i_ORI  , i_XORI, i_JAL;
    wire i_MULT, i_MFLO , i_MFHI, i_MTLO;
    wire i_MTHI, i_MFC0 , i_MTC0;
    wire i_ERET, i_SYSCALL;
    wire op_zero;  
    wire sa_zero;  
    assign {      i_SYSCALL,
                  i_ERET, 
                  i_MTC0,
                  i_MFC0 , 
                  i_MTHI,
                  i_MTLO,
                  i_MFHI, 
                  i_MFLO , 
                  i_MULT, 
                  i_JAL,
                  i_XORI, 
                  i_ORI  , 
                  i_ANDI, 
                  i_SB,
                  i_LBU , 
                  i_LB   , 
                  i_BLTZ, 
                  i_BLEZ,
                  i_BGTZ, 
                  i_BGEZ , 
                  i_SLTI, 
                  i_SLTIU,
                  i_SRLV, 
                  i_SRAV , 
                  i_SRA , 
                  i_SLLV,
                  i_JR  ,
                  i_JALR ,  
                  i_SLTU, 
                  i_J,
                  i_LUI , 
                  i_SW   , 
                  i_LW  , 
                  i_BNE,
                  i_BEQ ,
                  i_ADDIU, 
                  i_SRL , 
                  i_SLL,
                  i_XOR , 
                  i_OR   , 
                  i_NOR , 
                  i_AND,
                  i_SLT , 
                  i_SUBU , 
                  i_ADDU, 
                  i_nop,
                  i_BREAK,
                  i_BGEZAL,
                  i_BLTZAL,
                  i_LHU,
                  i_LH,
                  i_SH,
                  i_MULTU,
                  i_DIVU,
                  i_DIV,
                  i_ADDI,
                  i_SUB,
                  i_ADD}=inst_result;

    wire i_jr;    
    wire i_j_link;
    wire i_b_link;
    wire i_jbr;  
    wire        j_valid;
    assign j_valid=1'b0;
    assign i_jr     = i_JALR | i_JR;
    assign i_j_link = i_JAL | i_JALR;
    assign i_b_link = i_BLTZAL|i_BGEZAL;
    assign i_jbr = i_J    | i_JAL  | i_jr
                    | i_BEQ  | i_BNE  | i_BGEZ
                    | i_BGTZ | i_BLEZ | i_BLTZ
                    | i_b_link;
    wire i_load;
    wire i_store;
    assign i_load  = i_LW | i_LB | i_LBU |i_LH |i_LHU;  
    assign i_store = i_SW | i_SB|i_SH;           
    
    wire i_add, i_sub, i_slt,i_sltu,i_addu,i_subu;
    wire i_and, i_nor, i_or, i_xor,i_ls;
    wire i_sll, i_srl, i_sra,i_lui;
    assign i_add = i_ADD  | i_ADDI | i_load
                    | i_store | i_j_link| i_b_link;            
    assign i_addu =i_ADDU|i_ADDIU;
    assign i_sub = i_SUB;                          
    assign i_subu = i_SUBU; 
    assign i_slt = i_SLT | i_SLTI;               
    assign i_sltu= i_SLTIU | i_SLTU;              
    assign i_and = i_AND | i_ANDI;               
    assign i_nor = i_NOR;                           
    assign i_or  = i_OR  | i_ORI;               
    assign i_xor = i_XOR | i_XORI;              
    assign i_sll = i_SLL | i_SLLV;              
    assign i_srl = i_SRL | i_SRLV;           
    assign i_sra = i_SRA | i_SRAV;             
    assign i_lui = i_LUI;                       
    

    wire i_shf_sa;
    assign i_shf_sa =  i_SLL | i_SRL | i_SRA;
    

    wire i_imm_zero; 
    wire i_imm_sign; 
    assign i_imm_zero = i_ANDI  | i_LUI  | i_ORI | i_XORI;
    assign i_imm_sign = i_ADDI |i_ADDIU | i_SLTI | i_SLTIU
                         | i_load | i_store;
    

    wire i_wdest_rt;  
    wire i_wdest_31;  
    wire i_wdest_rd;  
    assign i_wdest_rt = i_imm_zero | i_ADDIU | i_ADDI | i_SLTI
                         | i_SLTIU | i_load | i_MFC0;
    assign i_wdest_31 = i_JAL | i_BLTZAL|i_BGEZAL;
    assign i_wdest_rd = i_ADD |i_ADDU | i_SUBU| i_SUB | i_SLT  | i_SLTU
                         | i_JALR | i_AND  | i_NOR  | i_OR 
                            | i_XOR  | i_SLL  | i_SLLV | i_SRA 
                         | i_SRAV | i_SRL  | i_SRLV
                         | i_MFHI | i_MFLO;
                         

    wire no_rs;  
    wire no_rt;  
    assign no_rs = i_MTC0 | i_SYSCALL | i_ERET|i_BREAK;
    assign no_rt = i_ADDI |i_ADDIU | i_SLTI | i_SLTIU
                      | i_BGEZ  | i_load | i_imm_zero
                      | i_J     | i_JAL  | i_MFC0
                      | i_SYSCALL | i_BLTZAL|i_BGEZAL|i_BREAK;

    wire [31:0] bd_pc;  
    assign bd_pc = pc + 3'b100;
    

    wire        j_taken;
    wire [31:0] j_target;

    assign j_taken = i_J | i_JAL | i_jr;

    assign j_target = i_jr ? rs_value : {bd_pc[31:28],target,2'b00};


    wire rs_ez;
    wire rs_ltz;
  
    assign rs_ez       = ~(|rs_value);           
 
    wire br_taken;
    wire [31:0] br_target;
    assign br_taken = i_BEQ  & (rs_value == rt_value)     
                    | i_BNE  & ~(rs_value == rt_value)      
                    | (i_BGEZ|i_BGEZAL) & ~rs_value[31]          
                    | i_BGTZ & ~rs_value[31] & ~rs_ez  
                    | i_BLEZ & (rs_value[31] | rs_ez)  
                    | (i_BLTZ |i_BLTZAL) & rs_value[31];          
    assign br_target[31:2] = bd_pc[31:2] + {{14{offset[15]}}, offset};  
    assign br_target[1:0]  = bd_pc[1:0];
    

    reg is_in_delay;
    reg next_delay;
    reg is_delay;
    always @(posedge clk)
    begin
        if (IF_over&&ID_allow_in)
        begin
            is_in_delay <= next_delay;
        end
    end
    assign jbr_valid = pc_valid?1'b0:(j_taken | br_taken) & ID_over; 
    assign jbr_pc = j_taken ? j_target : br_target;
    

    always @(posedge clk)
    begin
        if (!resetn)
        begin
            next_delay <= 1'b0;
        end
        else if (i_jbr==1'b1)
        begin
            next_delay <= 1'b1;
        end
        else if (i_jbr==1'b0)
        begin
            next_delay <= 1'b0;
        end
    end
    always @(posedge clk)
    begin
        if (!resetn)
        begin
            is_delay <= 1'b0;
        end
        else 
        begin
            is_delay <= next_delay;
        end
    end

    wire rs_wait;
    wire rt_wait;
    wire i_wait;
    assign rs_wait = ~no_rs & (rs!=5'd0) &~execancel
                   & ( (rs==EXE_wdest) | (rs==MEM_wdest) | (rs==WB_wdest) );
    assign rt_wait = ~no_rt & (rt!=5'd0) &~execancel
                   & ( (rt==EXE_wdest) | (rt==MEM_wdest) | (rt==WB_wdest) );
    
    assign ID_over = ID_valid & ~rs_wait & ~rt_wait & (~i_jbr | IF_over);

    wire multiply;       
    wire division;        
    wire divunsigned;        
    wire mthi;           
    wire mtlo;           
    assign multiply = i_MULT|i_MULTU;
    assign division = i_DIV|i_DIVU;
    assign divunsigned = i_DIVU|i_MULTU;
    assign mthi     = i_MTHI;
    assign mtlo     = i_MTLO;
    wire [13:0] alu_control;
    wire [31:0] alu_operand1;
    wire [31:0] alu_operand2;
    wire        no_inst;
    

    assign alu_operand1 = (i_j_link|i_b_link) ? pc : 
                          i_shf_sa ? {27'd0,sa} : rs_value;
    assign alu_operand2 = (i_j_link|i_b_link) ? 32'd8 :  
                          i_imm_zero ? {16'd0, imm} :
                          i_imm_sign ?  {{16{imm[15]}}, imm} : rt_value;
    assign alu_control = {i_add,       
                          i_addu,
                          i_sub,
                          i_subu,
                          i_slt,
                          i_sltu,
                          i_and,
                          i_nor,
                          i_or, 
                          i_xor,
                          i_sll,
                          i_srl,
                          i_sra,
                          i_lui};
      assign no_inst=(inst_result==58'b0);
 
    wire lb_sign;  
    wire ls_word;  
    wire ls_hword;  
    wire [4:0] mem_control; 
    wire [31:0] store_data;  
    assign lb_sign = i_LB|i_LH;
    assign ls_word = i_LW | i_SW;
    assign ls_hword = i_LH|i_LHU|i_SH;
    assign mem_control = {i_load,
                          i_store,
                          ls_word,
                          ls_hword,
                          lb_sign };
                          

    wire mfhi;
    wire mflo;
    wire mtc0;
    wire mfc0;
    wire [7 :0] cp0r_addr;
    wire       syscall;   
    wire       eret;
    wire       break;
    wire       rf_wen;    
    wire [4:0] rf_wdest;  
    assign cp0r_addr= {rd,cp0r_sel};
    assign rf_wen   = i_wdest_rt | i_wdest_31 | i_wdest_rd;
    assign rf_wdest = i_wdest_rt ? rt :     
                      i_wdest_31 ? 5'd31 : 
                      i_wdest_rd ? rd : 5'd0;
    assign store_data = rt_value;
    assign ID_EXE_bus = {division,divunsigned,multiply,mthi,mtlo,                 
                         alu_control,alu_operand1,alu_operand2,
                         mem_control,store_data,           
                         i_MFHI,i_MFLO,                         
                         i_MTC0,i_MFC0,cp0r_addr,i_SYSCALL,i_BREAK,i_ERET,no_inst,    
                         j_valid,pc_valid,is_in_delay,
                         rf_wen, rf_wdest,                    
                         pc};                                

endmodule
