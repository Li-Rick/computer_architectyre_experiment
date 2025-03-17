`timescale 1ps/1ps

module HazardDetectionUnit(
    input clk,
    input Branch_ID, rs1use_ID, rs2use_ID,//发生跳转以及使用了rs1和2的信号
    input[1:0] hazard_optype_ID, //ctrlunit传入
    input[4:0] rd_EXE, rd_MEM, rs1_ID, rs2_ID, rs2_EXE,//rd_EXE：ID_EXE rd_MEM:EX_MEM
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
    //reg_EM_flush没有用到
    hazard_optype_MEM <= hazard_optype_EXE ;//当reg_EM_flush为0时，reg中的指令不被flush,将hazard_opyupe传递
    hazard_optype_EXE <= hazard_optype_ID & {2{~reg_DE_flush}};
    end

    //Read after Write : 都使用了Rs1,需要将EXE阶段的rs1前递
    wire rs1_forward_1     =  rd_EXE && rs1use_ID && rs1_ID==rd_EXE && hazard_optype_EXE == hazard_optype_ALU;
    //EXE指令需要Load,而且下一条ID指令不为Store,这时前递够不到，要stall
    wire rs1_forward_stall = rd_EXE && rs1use_ID && rs1_ID==rd_EXE && hazard_optype_EXE == hazard_optype_LOAD && hazard_optype_ID !=hazard_optype_STORE;
    //需要将MEM阶段的rs1前递到ID阶段
    wire rs1_forward_2     = rd_MEM && rs1use_ID && rs1_ID == rd_MEM && hazard_optype_MEM == hazard_optype_ALU;
    //需要将MEM阶段的rs1前递到ID阶段，配合stall,相当于stall一个周期后hazard_optype传递到了MEM阶段
    wire rs1_forward_3     = rd_MEM && rs1use_ID && rs1_ID == rd_MEM && hazard_optype_MEM == hazard_optype_LOAD;

    //Read after Write : 都使用了Rs2,需要将EXE阶段的rs2前递
    wire rs2_forward_1     = rd_EXE && rs2use_ID && rs2_ID==rd_EXE && hazard_optype_EXE == hazard_optype_ALU;
    //EXE指令需要Load,而且下一条ID指令不为Store,这时前递够不到，要stall
    wire rs2_forward_stall = rd_EXE && rs2use_ID && rs2_ID==rd_EXE && hazard_optype_EXE == hazard_optype_LOAD && hazard_optype_ID != hazard_optype_STORE;
    //需要将MEM阶段的rs1前递到ID阶段
    wire rs2_forward_2     = rd_MEM && rs2use_ID && rs2_ID == rd_MEM && hazard_optype_MEM == hazard_optype_ALU;
    //需要将MEM阶段的rs1前递到ID阶段，配合stall,相当于stall一个周期后hazard_optype传递到了MEM阶段
    wire rs2_forward_3     = rd_MEM && rs2use_ID && rs2_ID == rd_MEM && hazard_optype_MEM == hazard_optype_LOAD;
    //rs1的前递
    assign forward_ctrl_A = {2{rs1_forward_1}} & 2'd1 | {2{rs1_forward_2}} & 2'd2 | {2{rs1_forward_3}} & 2'd3 ;
    assign forward_ctrl_B = {2{rs2_forward_1}} & 2'd1 | {2{rs2_forward_2}} & 2'd2 | {2{rs2_forward_3}} & 2'd3 ;
    //Load+Store的情况，不需要用到ID阶段的东西，可以直接从MEM阶段判断，该信号为1时需要前递
    assign forward_ctrl_ls = rs2_EXE == rd_MEM &&
     hazard_optype_MEM == hazard_optype_LOAD && hazard_optype_EXE == hazard_optype_STORE;
    //需要使流水线stall 
    assign reg_FD_stall = rs1_forward_stall | rs2_forward_stall ;
    //当stall发生使需要将下一条指令清除，当stall结束后重新取值
    assign reg_DE_flush = rs1_forward_stall | rs2_forward_stall ;
    //发生跳转时需要将进入流水线的指令flush
    assign reg_FD_flush = Branch_ID;
    //PC使能在没有停顿时为1，可以被更新
    assign PC_EN_IF = ~(rs1_forward_stall | rs2_forward_stall) ;
    assign reg_FD_EN = 1;
    assign reg_DE_EN = 1;
    assign reg_EM_EN = 1;
    assign reg_MW_EN = 1;
endmodule