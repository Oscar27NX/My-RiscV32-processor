// Wrapper module that integrates the Instruction Decoder, Control Unit, ALU Decoder and the ImmGen
module MyController (
    input wire clk,
    input wire rst,
    input wire [31:0] instr,  
    input wire Zero,            // From ALU

    // Outputs to Datapath 
    output wire d_jump,
    output wire d_branch,
    output wire d_sel_result,
    output wire d_we_dm,
    output wire d_alu_control,
    output wire d_sel_alu_src_b,
    output wire [31:0] d_sel_ext,
    output wire d_we_rf
);

    // Internal wires connecting Decoder to FSM/ALU_Dec
    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;
    wire [1:0] alu_op; 

    // Instruction Decoder (Extraction + Sign Extension)
    MyInstructionDecoder ID (
        .instr(instr),
        .opcode(opcode),
        .funct3(funct3),
        .funct7(funct7),
        .imm_ext(d_sel_ext)
    );

    // Main Control Unit
    Main_Decoder CU (
        .opcode(opcode),
        .reg_write(d_we_rf),
        .mem_write(d_we_dm),
        .alu_src(d_sel_alu_src_b),
        .result_src(d_sel_result),
        .branch(d_branch),
        .jump(d_jump),
        .alu_op(alu_op)
    );

    // ALU Decoder
    ALU_Decoder ALU_Dec (
        .ALUOp(alu_op),
        .funct3(funct3),
        .funct7(funct7),
        .opcode(opcode),
        .ALUControl(d_alu_control)
    );

    // immediate generator is integrated in the Instruction Decoder



endmodule