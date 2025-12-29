// Top level module that is only tricky because we gotta stick to the stages in the manual
module rv_pl(
    input wire clk,
    input wire rst_n // Active low reset per manual [cite: 361]
);
    wire rst = ~rst_n; // Convert to active high for internal logic if needed

    // ============================================
    // 1. FETCH STAGE (F)
    // ============================================
    wire [31:0] F_pc, F_pc_plus_4, F_instr;
    wire [31:0] F_pc_next; // From Mux
    wire F_stall = 0; // Placeholder for Hazard Unit
    wire F_flush = 0; // Placeholder for Hazard Unit

    // PC Mux (Next PC Logic)
    assign F_pc_next = (E_branch_taken) ? E_target_pc : F_pc_plus_4; // Branch logic usually in EX

    MyProgramCounter PC (
        .clk(clk), .rst(rst), .en(!F_stall), // Enable needed for stall [cite: 194]
        .pc_in(F_pc_next), .pc_out(F_pc)
    );

    // Adder for PC+4
    assign F_pc_plus_4 = F_pc + 4;

    // Instruction Memory
    your_instruction_mem IMEM ( // Manual requires this name [cite: 372]
        .addr(F_pc), .rd(F_instr)
    );

    // ============================================
    // PIPE: IF -> ID
    // ============================================
    wire [31:0] D_pc, D_instr;
    
    FD_Register PLR1 (
        .clk(clk), .rst(rst), .en(!F_stall), .clr(F_flush),
        .pc_in(F_pc), .instr_in(F_instr),
        .pc_out(D_pc), .instr_out(D_instr)
    );

    // ============================================
    // 2. DECODE STAGE (D)
    // ============================================
    wire [31:0] D_imm, D_rs1_data, D_rs2_data;
    wire [4:0]  D_rd = D_instr[11:7];
    // Control Signals generated here
    wire D_rf_we, D_dmem_we, D_sel_src_b;
    wire [1:0] D_sel_result;
    wire [3:0] D_alu_control;

    // Controller (Wraps Decoder + Control Unit)
    MyController Controller (
        .clk(clk), .rst(rst),
        .instr(D_instr), .Zero(1'b0), // Zero not used in ID usually
        .d_we_rf(D_rf_we),
        .d_we_dm(D_dmem_we),
        .d_sel_alu_src_b(D_sel_src_b),
        .d_sel_result(D_sel_result),
        .d_alu_control(D_alu_control),
        .imm_ext(D_imm) // Fixed 32-bit output
    );

    // Register File
    // Note: Write ports come from WRITEBACK stage signals (W_*)
    your_reg_file_module RF ( // Manual requires this name [cite: 368]
        .clk(clk), 
        .rs1(D_instr[19:15]), .rs2(D_instr[24:20]), 
        .rd(W_rd),          // Feedback from Writeback
        .we(W_rf_we),       // Feedback from Writeback
        .w_data(W_result),  // Feedback from Writeback
        .rd1(D_rs1_data), .rd2(D_rs2_data)
    );

    // ============================================
    // PIPE: ID -> EX
    // ============================================
    wire [31:0] E_rs1_data, E_rs2_data, E_imm, E_pc;
    wire [4:0]  E_rd;
    wire E_rf_we, E_dmem_we, E_sel_src_b;
    wire [1:0] E_sel_result;
    wire [3:0] E_alu_control;

    DE_Register PLR2 (
        .clk(clk), .rst(rst), .clr(E_flush),
        // Data inputs
        .rs1_data_in(D_rs1_data), .rs2_data_in(D_rs2_data), 
        .imm_in(D_imm), .pc_in(D_pc), .rd_in(D_rd),
        // Control inputs
        .rf_we_in(D_rf_we), .dmem_we_in(D_dmem_we), 
        .sel_src_b_in(D_sel_src_b), .sel_result_in(D_sel_result),
        .alu_control_in(D_alu_control),
        // Outputs (E_*)
        .rs1_data_out(E_rs1_data), .rs2_data_out(E_rs2_data), 
        /* ... map all outputs ... */
    );

    // ============================================
    // 3. EXECUTE STAGE (E)
    // ============================================
    wire [31:0] E_alu_src_a, E_alu_src_b, E_alu_result;
    
    // Muxes (Note: Forwarding logic will replace E_rs1_data later)
    assign E_alu_src_a = E_rs1_data; 
    assign E_alu_src_b = (E_sel_src_b) ? E_imm : E_rs2_data;

    MyALU ALU (
        .operand_a(E_alu_src_a), .operand_b(E_alu_src_b),
        .alu_control(E_alu_control),
        .alu_result(E_alu_result),
        .zero(E_zero)
    );

    // ============================================
    // PIPE: EX -> MEM
    // ============================================
    wire [31:0] M_alu_result, M_write_data;
    wire [4:0]  M_rd;
    wire M_rf_we, M_dmem_we;
    wire [1:0] M_sel_result;

    EM_Register PLR3 (
        /* Connect E_* signals to inputs, M_* to outputs */
    );

    // ============================================
    // 4. MEMORY STAGE (M)
    // ============================================
    wire [31:0] M_read_data;

    your_data_mem DMEM ( // Manual requires this name [cite: 377]
        .clk(clk), .we(M_dmem_we),
        .addr(M_alu_result), .wd(M_write_data),
        .rd(M_read_data)
    );

    // ============================================
    // PIPE: MEM -> WB
    // ============================================
    wire [31:0] W_alu_result, W_read_data;
    wire [4:0]  W_rd;
    wire W_rf_we;
    wire [1:0] W_sel_result;

    MW_Register PLR4 (
        /* Connect M_* signals to inputs, W_* to outputs */
    );

    // ============================================
    // 5. WRITEBACK STAGE (W)
    // ============================================
    wire [31:0] W_result;

    // Result Mux (Selects between ALU result, Mem data, or PC+4)
    assign W_result = (W_sel_result == 2'b00) ? W_alu_result :
                      (W_sel_result == 2'b01) ? W_read_data :
                      32'b0; // Handle PC+4 if needed

endmodule