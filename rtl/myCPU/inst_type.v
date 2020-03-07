`timescale 1ns / 1ps



module inst_type(
        input [5:0]op,
        input [4:0]rd,
        input [4:0]sa,
        input [5:0]funct,
        input [4:0]rt,
        input [4:0]rs,
        input  [31:0]f_inst,
        output [57:0]i_type
    );
  
    
    wire op_zero; 
    wire sa_zero;  
    assign op_zero = ~(|op);
    assign sa_zero = ~(|sa);
   assign i_type[0]  = op_zero & sa_zero    & (funct == 6'b100000);
    assign i_type[13]  = op_zero & sa_zero    & (funct == 6'b100001);
    
    assign i_type[14]  = op_zero & sa_zero    & (funct == 6'b100011);
    assign i_type[1]  = op_zero & sa_zero    & (funct == 6'b100010);
    assign i_type[15]   = op_zero & sa_zero    & (funct == 6'b101010);
    assign i_type[29]  = op_zero & sa_zero    & (funct == 6'b101011);
    assign i_type[30]  = op_zero & (rt==5'd0) & (rd==5'd31)
                      & sa_zero & (funct == 6'b001001);       
    assign i_type[31]    = op_zero & (rt==5'd0) & (rd==5'd0 )
                      & sa_zero & (funct == 6'b001000);            
    assign i_type[16]   = op_zero & sa_zero    & (funct == 6'b100100);
    assign i_type[17]   = op_zero & sa_zero    & (funct == 6'b100111);
    assign i_type[18]    = op_zero & sa_zero    & (funct == 6'b100101);
    assign i_type[19]   = op_zero & sa_zero    & (funct == 6'b100110);
    assign i_type[20]   = op_zero & (rs==5'd0) & (funct == 6'b000000);
    assign i_type[32]  = op_zero & sa_zero    & (funct == 6'b000100);
    assign i_type[33]   = op_zero & (rs==5'd0) & (funct == 6'b000011);
    assign i_type[34]  = op_zero & sa_zero    & (funct == 6'b000111);
    assign i_type[21]   = op_zero & (rs==5'd0) & (funct == 6'b000010);
    assign i_type[35]  = op_zero & sa_zero    & (funct == 6'b000110);
    assign i_type[3]  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011010);            
    assign i_type[4]  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011011);                        
    assign i_type[49]  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011000);             
    assign i_type[5]  = op_zero & (rd==5'd0)
                      & sa_zero & (funct == 6'b011001);             
    assign i_type[50]  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010010);             
    assign i_type[51]  = op_zero & (rs==5'd0) & (rt==5'd0)
                      & sa_zero & (funct == 6'b010000);             
    assign i_type[52]  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010011);             
    assign i_type[53]  = op_zero & (rt==5'd0) & (rd==5'd0)
                      & sa_zero & (funct == 6'b010001);             
    assign i_type[2] = (op == 6'b001000);                             
    assign i_type[22] = (op == 6'b001001);            
    assign i_type[37]  = (op == 6'b001010);           
    assign i_type[36] = (op == 6'b001011);           
    assign i_type[23]   = (op == 6'b000100);             
    assign i_type[38]  = (op == 6'b000001) & (rt==5'd1);
    assign i_type[10]  = (op == 6'b000001) & (rt==5'b10001);
    assign i_type[39]  = (op == 6'b000111) & (rt==5'd0);
    assign i_type[40]  = (op == 6'b000110) & (rt==5'd0);
    assign i_type[41]  = (op == 6'b000001) & (rt==5'd0);
    assign i_type[9]  = (op == 6'b000001) & (rt==5'b10000);
    assign i_type[24]   = (op == 6'b000101);             
    assign i_type[25]    = (op == 6'b100011);             
    assign i_type[6]    = (op == 6'b101001);            
    assign i_type[26]    = (op == 6'b101011);           
    
    assign i_type[42]    = (op == 6'b100000);          
    assign i_type[43]   = (op == 6'b100100);            
    assign i_type[7]    = (op == 6'b100001);          
    assign i_type[8]   = (op == 6'b100101);           
    assign i_type[44]    = (op == 6'b101000);          
    assign i_type[45]  = (op == 6'b001100);           
    assign i_type[27]   = (op == 6'b001111) & (rs==5'd0);
    assign i_type[46]   = (op == 6'b001101);           
    assign i_type[47]  = (op == 6'b001110);            
    assign i_type[28]     = (op == 6'b000010);           
    assign i_type[48]   = (op == 6'b000011);          
    assign i_type[54]    = (op == 6'b010000) & (rs==5'd0) 
                        & sa_zero & (funct[5:3] == 3'b000); 
    assign i_type[55]    = (op == 6'b010000) & (rs==5'd4)
                        & sa_zero & (funct[5:3] == 3'b000); 
    assign i_type[57] = (op == 6'b000000) & (funct == 6'b001100); 
    assign i_type[11] = (op == 6'b000000) & (funct == 6'b001101); 
    assign i_type[56]    = (op == 6'b010000) & (rs==5'd16) & (rt==5'd0)
                        & (rd==5'd0) & sa_zero & (funct == 6'b011000);
    assign i_type[12]   =(f_inst==32'h00000000);
    
endmodule
