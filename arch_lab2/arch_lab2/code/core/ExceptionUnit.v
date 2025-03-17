`timescale 1ns / 1ps

module ExceptionUnit(
    input clk, rst,
    input csr_rw_in,//来自ctrlunit,为CSR指令时变成1
    input[1:0] csr_wsc_mode_in,//inst_MEM[13:12]，对应写、置1、置0
    input csr_w_imm_mux,//当需要使用立即数时置1
    input[11:0] csr_rw_addr_in,//inst_MEM[31:20]，CSR寄存器的索引
    input[31:0] csr_w_data_reg,//rs1_data_MEM，要写入CSR
    input[4:0] csr_w_data_imm,//rs1_MEM，rs1的位置
    output[31:0] csr_r_data_out,//CSRout_MEM，从CSR中读取的数据，要写入rd中

    input interrupt,//中断源，供将来使用
    input illegal_inst,//非法指令
    input l_access_fault,//~isFlushed_WB & exp_vector_WB[1]，WB没有被flush而且l_access_fault_MEM为1,没有正确load
    input s_access_fault,//~isFlushed_WB & exp_vector_WB[0]，WB没有被flush，而且s_access_fault_MEM为1，没有正确store
    input ecall_m,//~isFlushed_WB & exp_vector_WB[2]，WB没有被flush而且为需要跳转到异常处理

    input mret,//返回信号，从cs指令中返回

    input[31:0] epc_cur,
    input[31:0] epc_next,
    output[31:0] PC_redirect,
    output redirect_mux,

    output reg_FD_flush, reg_DE_flush, reg_EM_flush, reg_MW_flush, 
    output RegWrite_cancel
);

    reg[11:0] csr_raddr, csr_waddr;
    reg[31:0] csr_wdata;
    reg csr_w;
    reg[1:0] csr_wsc;

    wire[31:0] mstatus;

    CSRRegs csr(.clk(clk),.rst(rst),.csr_w(csr_w),.raddr(csr_raddr),.waddr(csr_waddr),
        .wdata(csr_wdata),.rdata(csr_r_data_out),.mstatus(mstatus),.csr_wsc_mode(csr_wsc));

    //According to the diagram, design the Exception Unit

endmodule