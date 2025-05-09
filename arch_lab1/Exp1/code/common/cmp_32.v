`timescale 1ns / 1ps

module cmp_32(  input [31:0] a,
                input [31:0] b,
                input [2:0] ctrl,
                output c
    );
    parameter cmp_EQ  = 3'b000;
    parameter cmp_NE  = 3'b001;
    parameter cmp_LT  = 3'b100;
    parameter cmp_LTU = 3'b110;
    parameter cmp_GE  = 3'b101;
    parameter cmp_GEU = 3'b111;

    wire res_EQ  = a == b;//相等
    wire res_NE  = ~res_EQ;//不等
    wire res_LT  = (a[31] & ~b[31]) || (~(a[31] ^ b[31]) && a < b);//less than
    wire res_LTU = a < b;//无符号小于
    wire res_GE  = ~res_LT;//great than
    wire res_GEU = ~res_LTU;//无符号大于

    wire EQ  = ctrl == cmp_EQ ; 
    wire NE  = ctrl == cmp_NE ; 
    wire LT  = ctrl == cmp_LT ; 
    wire LTU = ctrl == cmp_LTU;
    wire GE  = ctrl == cmp_GE ; 
    wire GEU = ctrl == cmp_GEU;

    assign c = ((EQ & res_EQ) | (NE & res_NE) | (LT & res_LT) | (LTU | res_LTU) | (GE & res_GE) | (GEU & res_GEU));          //to fill sth. in ()

endmodule