module rv_pl(
    input wire clk,
    input wire rst_n
);
    // ============================================
    // SIGNAL DEFINITIONS
    // ============================================
    
    wire rst = ~rst_n; // Internal active-high reset
 
    // --- Fetch Stage (F) ---
    wire [31:0] F_pc, F_pc_p4, F_instr, F_pc_next;
    wire        F_stall; 
    wire        F_flush; 

    // --- Decode Stage (D) ---
    wire [31:0] D_pc, D_pc_p4, D_instr, D_imm_ext;
    wire [31:0] D_rf_rd1, D_rf_rd2;
    wire [4:0]  D_rf_a3; // Derived from instr
    
    // Controller Signals (D)
    wire        D_jump, D_branch, D_we_dm, D_sel_alu_src_b, D_we_rf;
    wire [1:0]  D_sel_result;
    wire [3:0]  D_alu_control;

    // --- Execute Stage (E) ---
    wire [31:0] E_pc, E_pc_p4, E_rf_rd1, E_rf_rd2, E_ext;
    wire [31:0] E_alu_src_a, E_alu_src_b, E_alu_o, E_target_pc;
    wire [4:0]  E_rf_a3;
    
    // Controller Signals (E)
    wire        E_jump, E_branch, E_we_dm, E_sel_alu_src_b, E_we_rf;
    wire [1:0]  E_sel_result;
    wire [3:0]  E_alu_control;
    wire        E_zero, E_flush;

    // --- Memory Stage (M) ---
    wire [31:0] M_pc_p4, M_alu_o, M_dm_wd, M_dm_rd;
    wire [4:0]  M_rf_a3;
    wire        M_we_dm, M_we_rf;
    wire [1:0]  M_sel_result;

    // --- Writeback Stage (W) ---
    wire [31:0] W_pc_p4, W_alu_o, W_dm_rd, W_result;
    wire [4:0]  W_rf_a3;
    wire        W_we_rf;
    wire [1:0]  W_sel_result;

    // Control Logic for Branching
    wire PC_Src; 
    assign PC_Src = E_jump | (E_branch & E_zero);

    // Hazard Placeholders (Until Hazard Unit is added)
    assign F_stall = 1'b0; 
    assign F_flush = PC_Src; // Flush Fetch if Branch Taken
    assign E_flush = PC_Src; // Flush Decode if Branch Taken

    // ============================================
    // FETCH STAGE
    // ============================================

    // PC Mux
    assign F_pc_next = (PC_Src) ? E_target_pc : F_pc_p4;

    MyProgramCounter PC (
        .clk    (clk),
        .rst    (rst),
        .en     (!F_stall),
        .pc_in  (F_pc_next),
        .pc_out (F_pc)
    );

    MyAdder PC_Adder (
        .a      (F_pc),
        .b      (32'd4),
        .sum    (F_pc_p4)
    );

    imem IMEM (
        .addr   (F_pc),
        .rd     (F_instr)
    );

    // ============================================
    // PIPE: F -> D
    // ============================================
    FD_register PLR1 (
        .clk     (clk),
        .rst_n   (rst_n),
        .stall   (F_stall),
        .flush   (F_flush),
        .F_pc    (F_pc),
        .F_pc4   (F_pc_p4),
        .F_instr (F_instr),
        .D_pc    (D_pc),
        .D_pc4   (D_pc_p4),
        .D_instr (D_instr)
    );

    // ============================================
    // DECODE STAGE
    // ============================================

    // Split Instruction for RegFile
    assign D_rf_a3 = D_instr[11:7]; // rd

    MyController Controller (
        .clk             (clk),
        .rst             (rst),
        .instr           (D_instr),
        .Zero            (1'b0), // Not used in ID
        
        // Output Mappings
        .d_jump          (D_jump),
        .d_branch        (D_branch),
        .d_sel_result    (D_sel_result),
        .d_we_dm         (D_we_dm),
        .d_alu_control   (D_alu_control),
        .d_sel_alu_src_b (D_sel_alu_src_b),
        .d_we_rf         (D_we_rf),
        .imm_ext         (D_imm_ext)
    );

    RegisterFile RF (
        .clk        (clk),
        .rs1        (D_instr[19:15]),
        .rs2        (D_instr[24:20]),
        .rd         (W_rf_a3),      // Feedback from WB
        .write_data (W_result),     // Feedback from WB
        .reg_write  (W_we_rf),      // Feedback from WB
        .read_data1 (D_rf_rd1),
        .read_data2 (D_rf_rd2)
    );

    // ============================================
    // PIPE: D -> E
    // ============================================
    DE_Register PLR2 (
        .clk              (clk),
        .rst_n            (rst_n),
        .flush            (E_flush),
        
        // Data
        .D_pc             (D_pc),
        .D_rf_rd1         (D_rf_rd1),
        .D_rf_rd2         (D_rf_rd2),
        .D_ext            (D_imm_ext),
        .D_rf_a3          (D_rf_a3),
        .D_pc_p4          (D_pc_p4),
        
        // Control
        .D_jump           (D_jump),
        .D_branch         (D_branch),
        .D_sel_result     (D_sel_result),
        .D_we_dm          (D_we_dm),
        .D_alu_control    (D_alu_control),
        .D_sel_alu_src_b  (D_sel_alu_src_b),
        .D_we_rf          (D_we_rf),

        // Outputs
        .E_pc             (E_pc),
        .E_rf_rd1         (E_rf_rd1),
        .E_rf_rd2         (E_rf_rd2),
        .E_ext            (E_ext),
        .E_rf_a3          (E_rf_a3),
        .E_pc_p4          (E_pc_p4),
        
        .E_jump           (E_jump),
        .E_branch         (E_branch),
        .E_sel_result     (E_sel_result),
        .E_we_dm          (E_we_dm),
        .E_alu_control    (E_alu_control),
        .E_sel_alu_src_b  (E_sel_alu_src_b),
        .E_we_rf          (E_we_rf)
    );

    // ============================================
    // EXECUTE STAGE
    // ============================================

    // Branch Target Logic: E_pc + E_ext (Standard RISC-V)
    MyAdder Branch_Adder (
        .a      (E_pc), 
        .b      (E_ext),
        .sum    (E_target_pc)
    );

    // ALU Multiplexers
    assign E_alu_src_a = E_rf_rd1; // No Forwarding yet
    assign E_alu_src_b = (E_sel_alu_src_b) ? E_ext : E_rf_rd2;

    MyALU ALU (
        .alu_control (E_alu_control),
        .operand_a   (E_alu_src_a),
        .operand_b   (E_alu_src_b),
        .alu_result  (E_alu_o),
        .zero        (E_zero)
    );

    // ============================================
    // PIPE: E -> M
    // ============================================
    EM_Register PLR3 (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // Data
        .E_alu_o        (E_alu_o),
        .E_dm_wd        (E_rf_rd2), // Data to write to mem is RS2
        .E_rf_a3        (E_rf_a3),
        .E_pc_p4        (E_pc_p4),
        
        // Control
        .E_sel_result   (E_sel_result),
        .E_we_dm        (E_we_dm),
        .E_we_rf        (E_we_rf),

        // Outputs
        .M_alu_o        (M_alu_o),
        .M_dm_wd        (M_dm_wd),
        .M_rf_a3        (M_rf_a3),
        .M_pc_p4        (M_pc_p4),
        
        .M_sel_result   (M_sel_result),
        .M_we_dm        (M_we_dm),
        .M_we_rf        (M_we_rf)
    );

    // ============================================
    // MEMORY STAGE
    // ============================================

    dmem DMEM (
        .clk    (clk),
        .we     (M_we_dm),
        .addr   (M_alu_o),
        .wd     (M_dm_wd),
        .rd     (M_dm_rd)
    );

    // ============================================
    // PIPE: M -> W
    // ============================================
    MW_Register PLR4 (
        .clk            (clk),
        .rst_n          (rst_n),
        
        // Data
        .M_dm_rd        (M_dm_rd),
        .M_alu_o        (M_alu_o),
        .M_rf_a3        (M_rf_a3),
        .M_pc_p4        (M_pc_p4),
        
        // Control
        .M_sel_result   (M_sel_result),
        .M_we_rf        (M_we_rf),

        // Outputs
        .W_dm_rd        (W_dm_rd),
        .W_alu_o        (W_alu_o),
        .W_rf_a3        (W_rf_a3),
        .W_pc_p4        (W_pc_p4),
        
        .W_sel_result   (W_sel_result),
        .W_we_rf        (W_we_rf)
    );

    // ============================================
    // WRITEBACK STAGE
    // ============================================

    // Result Mux: 00=ALU, 01=Mem, 10=PC+4
    assign W_result = (W_sel_result == 2'b00) ? W_alu_o :
                      (W_sel_result == 2'b01) ? W_dm_rd :
                      (W_sel_result == 2'b10) ? W_pc_p4 : 32'b0;

endmodule