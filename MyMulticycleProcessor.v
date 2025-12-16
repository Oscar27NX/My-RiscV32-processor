module MyMulticycleProcessor (
    input wire clk,
    input wire rst
);
    
    // --- 1. Wires & Control Signals ---
    wire pc_update, sel_mem_addr, dmem_we, ir_we, rf_we;
    wire [1:0] sel_result;
    wire [1:0] sel_alu_src_a;
    wire [1:0] sel_alu_src_b;
    wire [3:0] alu_control;
    wire [31:0] imm_ext;

    // --- 2. Data Path Signals ---
    wire [31:0] pc_current, pc_input_mux_out;
    wire [31:0] instr_out;              
    wire [31:0] mem_read_data;          
    wire [31:0] instr_mem_out;          
    wire [31:0] read_data1, read_data2; 
    wire [31:0] alu_result;
    wire zero_flag;
    wire [31:0] src_a, src_b;
    wire [31:0] write_back_data;
    
    // --- 3. Pipeline Registers ---
    reg [31:0] data_reg;    
    reg [31:0] A_reg;       
    reg [31:0] B_reg;       
    reg [31:0] alu_out_reg; 

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            data_reg    <= 32'b0;
            A_reg       <= 32'b0;
            B_reg       <= 32'b0;
            alu_out_reg <= 32'b0;
        end else begin
            data_reg    <= mem_read_data; 
            A_reg       <= read_data1;    
            B_reg       <= read_data2;    
            alu_out_reg <= alu_result;    
        end
    end

    // --- 4. Module Instantiations ---

    // A. Control Unit
    MyController Controller (
        .clk(clk),
        .rst(rst),
        .instr(instr_out),
        .Zero(zero_flag),
        .pc_update(pc_update),
        .sel_mem_addr(sel_mem_addr),
        .dmem_we(dmem_we),
        .ir_we(ir_we),
        .rf_we(rf_we),
        .sel_result(sel_result),
        .sel_alu_src_a(sel_alu_src_a),
        .sel_alu_src_b(sel_alu_src_b),
        .alu_control(alu_control),
        .imm_ext(imm_ext)
    );

    // B. PC Logic
    MyMultiplexer PC_Enable_Mux (
        .sel(pc_update),
        .b(pc_current),      
        .a(write_back_data),      
        .y(pc_input_mux_out)
    );

    MyProgramCounter PC_Unit (
        .clk(clk),
        .rst(rst),
        .pc_in(pc_input_mux_out),
        .pc_out(pc_current)
    );

    // C. Instruction Memory (Code)
    // RENAMED MODULE: MyMemory
    MyMemory I_MEM (
        .clk(clk),
        .we(1'b0),          
        .addr(pc_current),
        .wd(32'b0),         
        .rd(instr_mem_out)
    );

    // D. Data Memory (Heap/Stack)
    // RENAMED MODULE: MyMemory
    MyMemory MEM (
        .clk(clk),
        .we(dmem_we),
        .addr(alu_out_reg),
        .wd(B_reg),         
        .rd(mem_read_data)
    );

    // E. Instruction Register (IR)
    InstructionRegister IR_Unit (
        .clk(clk),
        .rst(rst),
        .ir_write(ir_we),
        .mem_data(instr_mem_out), 
        .instr(instr_out)
    );

    // F. Register File
    MyRegisterFile Reg_File (
        .clk(clk),
        .reg_write(rf_we),
        .rs1_sel(instr_out[19:15]),
        .rs2_sel(instr_out[24:20]),
        .rd_reg(instr_out[11:7]),
        .write_data(write_back_data),
        .read_data1(read_data1),
        .read_data2(read_data2)
    );

    // G. ALU Inputs
    wire [31:0] src_a_temp;

    // Mux 1 (Lower): Bit 0 selects between PC (0) and Constant 0 (1)
    MyMultiplexer SrcA_Mux_Lower (
        .sel(sel_alu_src_a[0]), 
        .b(pc_current),      // Default (00)
        .a(32'b0),           // LUI Case (01) -> Constant 0
        .y(src_a_temp)
    );

    // Mux 2 (Upper): Bit 1 selects between Lower Result (0) and A_reg (1)
    MyMultiplexer SrcA_Mux_Upper (
        .sel(sel_alu_src_a[1]), 
        .b(src_a_temp),      // From Lower Mux
        .a(A_reg),           // R-Type/Branch (10)
        .y(src_a)
    );

    wire [31:0] src_b_temp;
    MyMultiplexer SrcB_Mux_Lower (
        .sel(sel_alu_src_b[0]),
        .b(B_reg),
        .a(imm_ext),
        .y(src_b_temp)
    );
    MyMultiplexer SrcB_Mux_Upper (
        .sel(sel_alu_src_b[1]),
        .b(src_b_temp),
        .a(32'd4),
        .y(src_b)
    );

    // H. ALU
    MyALU Main_ALU (
        .alu_control(alu_control),
        .operand_a(src_a),
        .operand_b(src_b),
        .alu_result(alu_result),
        .zero(zero_flag)
    );

    // I. Result Mux
    wire [31:0] wb_temp;
    MyMultiplexer WB_Mux_Lower (
        .sel(sel_result[0]),
        .b(alu_out_reg),
        .a(data_reg),
        .y(wb_temp)
    );
    MyMultiplexer WB_Mux_Upper (
        .sel(sel_result[1]),
        .b(wb_temp),
        .a(alu_result),
        .y(write_back_data)
    );

endmodule