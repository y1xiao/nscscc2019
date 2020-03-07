`timescale 1ns / 1ps



module division(
    input         clk,       
    input         Unsigned,
    input         div_begin,
    input  [31:0] div_op1,   
    input  [31:0] div_op2,   
    output [63:0] product,   
    output        div_end   
    );
    reg div_valid;
    reg div_end1;
    reg  [5:0] cnt;
    reg  [63:0] dividend;
    reg  [63:0] remainder_temp;
    reg  [31:0] quotient_temp;
    wire        op1_sign;     
    wire        op2_sign;     
    wire [31:0] op1_absolute;  
    wire [31:0] op2_absolute;  
    assign op1_sign = div_op1[31];
    assign op2_sign = div_op2[31];
    assign op1_absolute = (op1_sign&!Unsigned) ? (~div_op1+1) : div_op1;
    assign op2_absolute = (op2_sign&!Unsigned) ? (~div_op2+1) : div_op2;
    assign div_end = div_end1;

    always @(posedge clk)
    begin
        if (!div_begin || div_end1)
        begin
            div_valid <= 1'b0;
        end
        else
        begin
            div_valid <= 1'b1;
        end
    end
    always @ (posedge clk)
    begin
        if(cnt==6'b100000)
        begin
           div_end1 <= 1'b1;
           cnt <= cnt + 1;
        end
        else if(cnt==6'b100001)
        begin
           div_end1 <= 1'b0;
           cnt <= cnt + 1;
        end
        else if (div_valid)
        begin    
            dividend<={1'b0,dividend[63:1]};
            cnt <= cnt + 1;
        end
        else if (div_begin) 
        begin   
            dividend<= {op2_absolute,32'd0};
            cnt<=6'b000000;   
        end
        else
        begin
           div_end1 <= 1'b0;
        end
    end
    
    wire [64:0] div_temp;
    wire div_tempop;
    assign div_temp = remainder_temp- dividend;
    assign div_tempop = Unsigned?div_temp[64]:div_temp[63];
    always @(posedge clk)
    begin
       if(div_tempop == 1'b1&&div_valid) 
       begin
          quotient_temp <= {quotient_temp[30:0] , 1'b0};
       end 
       else  if(div_valid)
       begin
          quotient_temp <= {quotient_temp[30:0], 1'b1};
          remainder_temp <= div_temp;
       end
       else if(div_begin)
       begin
          remainder_temp <= {32'd0,op1_absolute};
          quotient_temp<= {32'd0};
       end
   end
    reg quotient_sign;
    reg remainder_sign;
    wire  [31:0] remainder;
    wire  [31:0] quotient;
    
    always @ (posedge clk)  
    begin
        if (div_valid)
        begin
              quotient_sign <= Unsigned?1'b0:op1_sign ^ op2_sign;
              remainder_sign <= Unsigned?1'b0:op1_sign ^remainder_temp[31];
        end
    end 
    assign quotient = quotient_sign ? (~quotient_temp+1) : quotient_temp;
    assign remainder = remainder_sign ? (~remainder_temp+1) : remainder_temp;
    assign product = {remainder[31:0],quotient[31:0]};
    
    
endmodule
