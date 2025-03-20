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

    input[31:0] epc_cur,//接的是PC_WB，PC_WB来自前面的阶段对每个阶段进行判断，如果没有flush 就赋0；如果有flush，就取上一个阶段的PC。如果一直flush可以追溯到PCurrent_ID
    //这个阶段如果Data_stall/flush，就不进行异常处理，直接跳转到下一个阶段。
    //如果没有Data_stall/flush，就进行异常处理，PCurrent_ID<=PCOUT(就是PC_IF)
    input[31:0] epc_next,
    //接的是~isFlushed_MEM ? PC_MEM : ~isFlushed_EXE ? PC_EXE :~isFlushed_ID ? PC_ID : PC_IF 意思是哪个阶段如果发生异常，就跳转到哪个PC。如果都没有flush，就从PC_IF开始执行。
    output[31:0] PC_redirect,//接的是PC_redirect_exp 意思是如果发生异常，就把PC_redirect_exp的值写到PC_WB中，然后跳转到异常处理程序。
    output redirect_mux,//接的是redirect_mux_exp，最后传到CPUTEST的exp_sig中 意思是如果发生异常，就把redirect_mux_exp的值写到redirect_mux中，然后根据redirect_mux的值跳转到对应的异常处理程序。

    output reg_FD_flush, reg_DE_flush, reg_EM_flush, reg_MW_flush, //各个寄存器的flush
    output RegWrite_cancel //取消向寄存器中写
);

    reg[11:0] csr_raddr, csr_waddr;
    reg[31:0] csr_wdata;
    reg csr_w;
    reg[1:0] csr_wsc;
    reg[1:0] cur_state,next_state;

    // CSR接口信号
    wire [31:0] mstatus;
    wire [31:0] mepc;
    // CSR寄存器地址定义
    parameter MSTATUS = 12'h300;
    parameter MTVEC   = 12'h305;
    parameter MEPC    = 12'h341;
    parameter MCAUSE  = 12'h342;
    parameter MTVAL   = 12'h343;
   
    CSRRegs csr(.clk(clk),.rst(rst),.csr_w(csr_w),.raddr(csr_raddr),.waddr(csr_waddr),
        .wdata(csr_wdata),.rdata(csr_r_data_out),.mstatus(mstatus),.csr_wsc_mode(csr_wsc));

    //According to the diagram, design the Exception Unit
    localparam STATE_IDLE = 2'b00; //检测异常，存储附加异常信息，更新机器状态
    localparam STATE_MEPC = 2'b01; //更新mepc寄存器
    localparam STATE_MCAUSE = 2'b10; //更新mcause寄存器
    // 异常类型编码
    wire [31:0] exception_cause;
    assign exception_cause = 
        illegal_inst  ? 32'h2 :
        ecall_m       ? 32'hB :
        l_access_fault? 32'h5 :
        s_access_fault? 32'h7 :
        interrupt     ? {1'b1, 31'hB} : // 假设外部中断
        32'h0;

   always @(posedge clk or posedge rst) begin
        if (rst) cur_state <= STATE_IDLE;
        else cur_state <= next_state;
    end

    always @(*) begin
        case (cur_state)
            STATE_IDLE:begin
                if (|{illegal_inst, ecall_m, l_access_fault, s_access_fault, interrupt}) begin
                    csr_w <= csr_rw_in;
                    csr_waddr <= csr_rw_addr_in;
                    csr_wdata <= csr_w_imm_mux ? {27'b0, csr_w_data_imm} : csr_w_data_reg;
                    csr_wsc <= csr_wsc_mode_in;
                    next_state <= STATE_MEPC;
                end
                else if(mret)begin
                    csr_w <= 1;
                    csr_waddr <= MSTATUS;
                    csr_wdata <= mret ? {mstatus[31:8], 1'b0, mstatus[6:4], mstatus[7], mstatus[2:0]} :
                                      {mstatus[31:8], mstatus[3], mstatus[6:4], 1'b0, mstatus[2:0]};
                    next_state <= STATE_IDLE;
                end 
                else if(csr_rw_in)begin
                    csr_w <= csr_rw_in;
                    csr_waddr <= csr_rw_addr_in;
                    csr_wdata <= csr_w_imm_mux ? {27'b0, csr_w_data_imm} : csr_w_data_reg;
                    csr_wsc <= csr_wsc_mode_in;
                    next_state <= STATE_IDLE;
                end  
                else begin
                    csr_w = 0;
                    next_state <= STATE_IDLE;
                end     
            end 
            STATE_MEPC:begin
                csr_w <= 1;
                csr_waddr <= MEPC;
                csr_wdata <= (interrupt) ? epc_next : epc_cur;
                csr_wsc <= 2'b01;
            end
            STATE_MCAUSE:begin
                 csr_w <= 1;
                 csr_waddr <= MCAUSE;
                 csr_wdata <= exception_cause;
                 csr_wsc <= 2'b01;
            end
        endcase
    end
    always @(negedge clk) begin
        if (rst) begin
            csr_w <= 0;
            csr_waddr <= 0;
            csr_wdata <= 0;
            csr_wsc <= 0;
        end
    end
    // PC重定向控制
    assign PC_redirect = (cur_state == STATE_IDLE && mret) ? mepc : (cur_state != STATE_IDLE) ? csr_r_data_out : 32'h0;
    assign redirect_mux = (cur_state != STATE_IDLE || mret || csr_rw_in);

    assign reg_FD_flush = (cur_state != STATE_IDLE || mret);
    assign reg_DE_flush = (cur_state != STATE_IDLE || mret);
    assign reg_EM_flush = (cur_state != STATE_IDLE || mret);
    assign reg_MW_flush = (cur_state != STATE_IDLE);
    assign RegWrite_cancel = (cur_state != STATE_IDLE);

endmodule