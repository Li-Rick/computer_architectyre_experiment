`timescale 1ps/1ps

module HazardDetectionUnit(
    input clk,
    input Branch_ID, rs1use_ID, rs2use_ID,
    input[1:0] hazard_optype_ID,
    input[4:0] rd_EXE, rd_MEM, rs1_ID, rs2_ID, rs2_EXE,
    output PC_EN_IF, reg_FD_EN, reg_FD_stall, reg_FD_flush,
        reg_DE_EN, reg_DE_flush, reg_EM_EN, reg_EM_flush, reg_MW_EN,
    output forward_ctrl_ls,
    output[1:0] forward_ctrl_A, forward_ctrl_B
);
            //according to the diagram, design the Hazard Detection Unit
    parameter hazard_optype_ALU = 2'd1;
    parameter hazard_optype_LOAD = 2'd2;
    parameter hazard_optype_STORE = 2'd3;
    
    reg[1:0] hazard_optype_EXE, hazard_optype_MEM;
    always@(posedge clk) begin
    hazard_optype_MEM <= hazard_optype_EXE & {2{~reg_EM_flush}};
    hazard_optype_EXE <= hazard_optype_ID & {2{~reg_DE_flush}};
    end

    parameter hazard_optype_ALU = 2'd1;
    parameter hazard_optype_LOAD = 2'd2;
    parameter hazard_optype_STORE = 2'd3;

    wire rs1_forward_1     = ... && hazard_optype_EXE == hazard_optype_ALU;
    wire rs1_forward_stall = ...&& hazard_optype_EXE == hazard_optype_LOAD && hazard_optype_ID !=hazard_optype_STORE;
    wire rs1_forward_2     = ... && hazard_optype_MEM == hazard_optype_ALU;
    wire rs1_forward_3     = ... && hazard_optype_MEM == hazard_optype_LOAD;

    assign forward_ctrl_A = ...
    assign forward_ctrl_B = ...
    assign forward_ctrl_ls = ...

endmodule