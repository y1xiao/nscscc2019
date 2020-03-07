`timescale 1ns / 1ps

module multiply(              
    input         clk,       
    input        Unsigned,
    input         mult_begin, 
    input  [31:0] mult_op1,   
    input  [31:0] mult_op2,  
    output [63:0] product,  
    output        mult_end   
);


    reg mult_valid;
    reg  [31:0] multiplier;
    assign mult_end = mult_valid & ~(|multiplier); 
    always @(posedge clk)
    begin
        if (!mult_begin || mult_end)
        begin
            mult_valid <= 1'b0;
        end
        else
        begin
            mult_valid <= 1'b1;
        end
    end


    wire [31:0] op1_absolute;  
    wire [31:0] op2_absolute;  
    assign op1_absolute = (mult_op1[31]&!Unsigned) ? (~mult_op1+1) : mult_op1;
    assign op2_absolute = (mult_op2[31]&!Unsigned) ? (~mult_op2+1) : mult_op2;


    reg  [63:0] multiplicand;
    wire [1:0] next_zt;
    wire [3:0] next_zf;
    wire [7:0] next_ze; 
    wire [15:0] next_zfi;
    reg product_sign;
    assign next_zt = multiplier[1:0]==2'b0;
    assign next_zf = multiplier[3:0]==4'b0;
    assign next_ze = multiplier[7:0]==8'b0;
    assign next_zfi = multiplier[15:0]==16'b0;
    always @ (posedge clk)
    begin
        if (mult_valid&&next_zfi)
        begin   
            multiplicand <= {multiplicand[47:0],16'b0};
        end
        else if (mult_valid&&next_ze)
        begin    
            multiplicand <= {multiplicand[55:0],8'b0};
        end
        else if (mult_valid&&next_zf)
        begin    
            multiplicand <= {multiplicand[59:0],4'b0};
        end
        else if (mult_valid&&next_zt)
        begin   
            multiplicand <= {multiplicand[61:0],2'b0};
        end
        else if (mult_valid)
        begin    
            multiplicand <= {multiplicand[62:0],1'b0};
        end
        else if (mult_begin) 
        begin   
            multiplicand <= {32'd0,op1_absolute};
        end
    end
    
    always @ (posedge clk)
    begin
        if (mult_valid&&next_zfi)
        begin    
            multiplier <= {16'b0,multiplier[31:16]}; 
        end
        else if (mult_valid&&next_ze)
        begin    
            multiplier <= {8'b0,multiplier[31:8]}; 
        end
        else if (mult_valid&&next_zf)
        begin   
            multiplier <= {4'b0,multiplier[31:4]}; 
        end
        else if (mult_valid&&next_zt)
        begin    
            multiplier <= {2'b0,multiplier[31:2]}; 
        end
        else if (mult_valid)
        begin   
            multiplier <= {1'b0,multiplier[31:1]}; 
        end
        else if (mult_begin)
        begin   
            multiplier <= op2_absolute; 
        end
    end
    
    wire [63:0] partial_product;
    assign partial_product = multiplier[0] ? multiplicand : 64'd0;
    reg [63:0] product_temp;
    always @ (posedge clk)
    begin
        if (mult_valid)
        begin
            product_temp <= product_temp + partial_product;
        end
        else if (mult_begin) 
        begin
            product_temp <= 64'd0;  
        end
    end 
     


    always @ (posedge clk)  
    begin
        if (mult_valid)
        begin
              product_sign <= Unsigned?1'b0:mult_op1[31] ^ mult_op2[31];
        end
    end 
    assign product = product_sign ? (~product_temp+1) : product_temp;
endmodule
