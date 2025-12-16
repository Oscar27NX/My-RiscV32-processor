module Main_FSM (
    input wire clk,
    input wire rst,
    input wire [6:0] opcode,
    input wire Zero,

    // Outputs (flags and control signals)
    output reg pc_update,
    output reg sel_mem_addr,
    output reg dmem_we,
    output reg ir_we,
    output reg [1:0] sel_result,
    output reg [1:0] alu_op,
    output reg [1:0] sel_alu_src_a,
    output reg [1:0] sel_alu_src_b,
    output reg rf_we
);

    // State Encoding (S0 - S11)
    localparam S0_FETCH     = 4'd0;
    localparam S1_DECODE    = 4'd1;
    localparam S2_MEM_ADDR  = 4'd2;
    localparam S3_MEM_READ  = 4'd3;
    localparam S4_MEM_WB    = 4'd4;
    localparam S5_MEM_WRITE = 4'd5;
    localparam S6_EXEC_R    = 4'd6;
    localparam S7_EXEC_I    = 4'd7;
    localparam S8_ALU_WB    = 4'd8;
    localparam S9_BRANCH    = 4'd9;
    localparam S10_JAL      = 4'd10;
    localparam S11_LUI      = 4'd11;

    reg [3:0] state, next_state;

    // State Register
    always @(posedge clk or posedge rst) begin
        if (rst) state <= S0_FETCH;
        else     state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (state)
            S0_FETCH:    next_state = S1_DECODE;
            S1_DECODE: begin
                case (opcode)
                    7'b0000011: next_state = S2_MEM_ADDR; // LW
                    7'b0100011: next_state = S2_MEM_ADDR; // SW
                    7'b0110011: next_state = S6_EXEC_R;   // R-Type
                    7'b0010011: next_state = S7_EXEC_I;   // I-Type
                    7'b0110111: next_state = S11_LUI;     // LUI
                    7'b1101111: next_state = S10_JAL;     // JAL
                    7'b1100011: next_state = S9_BRANCH;   // BEQ
                    default:    next_state = S0_FETCH;
                endcase
            end
            S2_MEM_ADDR: begin
                if (opcode == 7'b0000011) next_state = S3_MEM_READ; // LW
                else                      next_state = S5_MEM_WRITE;// SW
            end
            S3_MEM_READ:  next_state = S4_MEM_WB;
            S4_MEM_WB:    next_state = S0_FETCH;
            S5_MEM_WRITE: next_state = S0_FETCH;
            S6_EXEC_R:    next_state = S8_ALU_WB;
            S7_EXEC_I:    next_state = S8_ALU_WB;
            S11_LUI:      next_state = S8_ALU_WB;
            S8_ALU_WB:    next_state = S0_FETCH;
            S9_BRANCH:    next_state = S0_FETCH;
            S10_JAL:      next_state = S0_FETCH;
            default:      next_state = S0_FETCH;
        endcase
    end

    // Output Logic
    always @(*) begin
        // Default Control Signals
        pc_update = 0; sel_mem_addr = 0; dmem_we = 0; ir_we = 0; rf_we = 0;
        sel_result = 2'b00; alu_op = 2'b00; sel_alu_src_a = 2'b00; sel_alu_src_b = 2'b00;

        case (state)
            // S0: Fetch 
            S0_FETCH: begin
                sel_mem_addr = 0;      // Select PC
                ir_we = 1;             // Write IR
                sel_alu_src_a = 2'b00; // Select PC
                sel_alu_src_b = 2'b10; // Select Constant 4 (YOUR SPECIFIC VALUE)
                alu_op = 2'b00;        // ADD
                sel_result = 2'b10;    // Select ALU Result (PC+4)
                pc_update = 1;         // Write PC
                dmem_we = 0;
            end

            // S1: Decode
            S1_DECODE: begin
                sel_alu_src_a = 2'b00; // PC (or OldPC)
                sel_alu_src_b = 2'b01; // Immediate
                alu_op = 2'b00;        // ADD
            end

            // S2: Memory Address Calc
            S2_MEM_ADDR: begin
                sel_alu_src_a = 2'b10; // Register A
                sel_alu_src_b = 2'b01; // Immediate
                alu_op = 2'b00;        // ADD
            end

            // S3: Memory Read
            S3_MEM_READ: begin
                sel_mem_addr = 1;      // Select ALUOut
            end

            // S4: Memory Writeback
            S4_MEM_WB: begin
                sel_result = 2'b01;    // Select Data Memory (MDR)
                rf_we = 1;
            end

            // S5: Memory Write
            S5_MEM_WRITE: begin
                sel_mem_addr = 1;      // Select ALUOut
                dmem_we = 1;
            end

            // S6: Execute R-Type
            S6_EXEC_R: begin
                sel_alu_src_a = 2'b10; // Register A
                sel_alu_src_b = 2'b00; // Register B
                alu_op = 2'b10;        // R-Type Func
            end

            // S7: Execute I-Type
            S7_EXEC_I: begin
                sel_alu_src_a = 2'b10; // Register A
                sel_alu_src_b = 2'b01; // Immediate
                alu_op = 2'b10;        // I-Type Func
            end

            // S8: ALU Writeback
            S8_ALU_WB: begin
                sel_result = 2'b00;    // Select ALUOut
                rf_we = 1;
            end

            // S9: Branch
            S9_BRANCH: begin
                sel_alu_src_a = 2'b10; // Register A
                sel_alu_src_b = 2'b00; // Register B
                alu_op = 2'b01;        // SUB
                sel_result = 2'b00;    // ALUOut (Target from Decode)
                if (Zero) pc_update = 1; 
            end

            // S10: JAL
            S10_JAL: begin
                pc_update = 1;
                sel_result = 2'b00;    // ALUOut (Target from Decode)
            end

           // S11: Execute LUI
            S11_LUI: begin
                // LUI: Result = 0 + Imm. 
                // CHANGED: Use 2'b01 to select Constant 0 on SrcA Mux
                sel_alu_src_a = 2'b01; // <--- WAS 2'b10
                sel_alu_src_b = 2'b01; // Immediate
                alu_op = 2'b00;        // ADD
            end
            
            default: ;
        endcase
    end
endmodule