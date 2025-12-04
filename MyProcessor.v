`timescale 1ns / 1ps

module MyProcessor (
    input wire clk,
    input wire rst
);

    // define PC & the Instruction variable
    wire [31:0] pc_current, pc_next, pc_plus_4, instruction;

    // address wires for branch and jump targets
    wire [31:0] branch_target_addr, jump_target_addr;

    // Signals for decoding instruction fields (see man)
    wire [6:0] opcode      = instruction[6:0];
    wire [4:0] rd_sel      = instruction[11:7];
    wire [2:0] funct3      = instruction[14:12];
    wire [4:0] rs1_sel     = instruction[19:15];
    wire [4:0] rs2_sel     = instruction[24:20];
    wire [6:0] funct7      = instruction[31:25];
    wire       funct7_b5   = instruction[30];

    // outputs of the control unit
    wire branch, mem_read, mem_write, reg_write, alu_src, jump, is_lui;
    wire [1:0] alu_op;
    wire [1:0] mem_to_reg; // Expanded to 2 bits for JAL support

    // Data Path Wires
    wire [31:0] rs1_data, rs2_data; // From RegFile
    wire [31:0] imm_out;            // From ImmGen
    wire [31:0] alu_operand_a;      // Actual input to ALU A (Handles LUI)
    wire [31:0] alu_operand_b;      // Actual input to ALU B (Handles ALUSrc)
    wire [3:0]  alu_control_sig;    // From ALU Control
    wire [31:0] alu_result;         // From ALU
    wire        zero_flag;          // From ALU (for BEQ)
    wire [31:0] mem_read_data;      // From Data Memory
    wire [31:0] write_back_data;    // Data written back to RegFile

    // Program Counter Register
    MyProgramCounter PC_Unit (
        .clk(clk),
        .rst(rst),
        .pc_in(pc_next),
        .pc_out(pc_current)
    );

    // PC + 4 Adder (four bits to next instruction)
    MyAdder Add_4_Unit (
        .a(pc_current),
        .b(32'd4),
        .sum(pc_plus_4)
    );

    // Instruction Memory
    MyInstructionMemory Instr_Mem (
        .address(pc_current),
        .instruction(instruction)
    );


    // Main Control Unit
    MyControlUnit Controller (
        .opcode(opcode),
        .branch(branch),
        .mem_read(mem_read),
        .mem_to_reg(mem_to_reg), // Expanded to 2 bits for JAL support
        .alu_op(alu_op),
        .mem_write(mem_write),
        .alu_src(alu_src),
        .reg_write(reg_write),
        .jump(jump),             
        .is_lui(is_lui)      
    );

    // Register File
    MyRegisterFile Reg_File (
        .clk(clk),
        .reg_write(reg_write),
        .rs1_sel(rs1_sel),
        .rs2_sel(rs2_sel),
        .rd_reg(rd_sel),
        .write_data(write_back_data),
        .read_data1(rs1_data),
        .read_data2(rs2_data)
    );

    // Immediate Generator (sign extension)
    MySignExt Imm_Gen (
        .instruction(instruction),
        .imm_out(imm_out)
    );


    // LUI Mux (Select 0 or RS1)
    MyMultiplexer LUI_Mux_Unit (
        .sel(is_lui),
        .reg_data(rs1_data),    // Input 0 (Normal)
        .sign_ext(32'b0),       // Input 1 (LUI case)
        .mux_out(alu_operand_a)
    );

    // ALU Src Mux (Select RS2 or Imm)
    MyMultiplexer ALUSrc_Mux_Unit (
        .sel(alu_src),
        .reg_data(rs2_data),    // Input 0
        .sign_ext(imm_out),     // Input 1
        .mux_out(alu_operand_b)
    );

    // ALU Control Decoder
    MyALUControl ALU_Dec (
        .alu_op(alu_op),
        .funct3(funct3),
        .funct7(funct7_b5), // Only bit 30 matters 
        .alu_ctrl_in(alu_control_sig)
    );

    // ALU
    MyALU Main_ALU (
        .alu_control(alu_control_sig),
        .operand_a(alu_operand_a),
        .operand_b(alu_operand_b),
        .alu_result(alu_result),
        .zero(zero_flag)
    );

    // Branch Target Calculator (PC + Imm)
    MyAdder Branch_Addr_Calc (
        .a(pc_current),
        .b(imm_out),
        .sum(branch_target_addr)
    );

    MyDataMemory Data_Mem (
        .clk(clk),
        .mem_write(mem_write),
        .address(alu_result),
        .write_data(rs2_data), // Store data always comes from RS2
        .read_data(mem_read_data)
    );

    // Write Back Mux (Handles JAL PC+4 logic)
    assign write_back_data = (mem_to_reg == 2'b00) ? alu_result :
                             (mem_to_reg == 2'b01) ? mem_read_data :
                             (mem_to_reg == 2'b10) ? pc_plus_4 : 32'b0;
    
    wire take_branch = branch & zero_flag;
    
    assign pc_next = (jump)        ? branch_target_addr : // JAL uses same math as Branch
                     (take_branch) ? branch_target_addr :
                                     pc_plus_4;

    // Now we are ready to do some synthesis and simulation

endmodule