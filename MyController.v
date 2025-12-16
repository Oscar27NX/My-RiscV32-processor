// Wrapper module that integrates the Instruction Decoder, Main FSM, and ALU Decoder
module MyController (
    input wire clk,
    input wire rst,
    input wire [31:0] instr,    // Full instruction from IR
    input wire Zero,            // From ALU

    // Outputs to Datapath 
    output wire pc_update,      
    output wire sel_mem_addr,   
    output wire dmem_we,        
    output wire ir_we,          
    output wire rf_we,          
    output wire [1:0] sel_result,   
    output wire [1:0] sel_alu_src_a,
    output wire [1:0] sel_alu_src_b, 
    output wire [3:0] alu_control,   
    output wire [31:0] imm_ext       
);

    // Internal wires connecting Decoder to FSM/ALU_Dec
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [1:0] alu_op; // Was ALUOp

    // 1. Instruction Decoder (Extraction + Sign Extension)
    MyInstructionDecoder ID (
        .instr(instr),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .imm_ext(imm_ext)
    );

    // 2. Main FSM (State Logic)
    Main_FSM FSM (
        .clk(clk),
        .rst(rst),
        .opcode(opcode),
        .Zero(Zero),
        .pc_update(pc_update),
        .sel_mem_addr(sel_mem_addr),
        .dmem_we(dmem_we),
        .ir_we(ir_we),
        .sel_result(sel_result),
        .alu_op(alu_op),
        .sel_alu_src_a(sel_alu_src_a),
        .sel_alu_src_b(sel_alu_src_b),
        .rf_we(rf_we)
    );

    // 3. ALU Decoder (Control Logic)
    ALU_Decoder AD (
        .ALUOp(alu_op),       // Connects to the internal wire 'alu_op'
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .ALUControl(alu_control) // Connects to the output wire 'alu_control'
    );

endmodule