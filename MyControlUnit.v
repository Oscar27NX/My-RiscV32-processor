module MyControlUnit(
    // 7-bit opcode from instruction
    input [6:0] opcode,
    output reg branch,
    output reg [1:0] alu_op,
    output reg mem_read,
    output reg [1:0] mem_to_reg,
    output reg mem_write,
    output reg alu_src,
    output reg reg_write,
    output reg jump,
    output reg is_lui
);

    always @(*) begin
        // reset values of all control signals
        branch = 0;
        mem_read = 0;
        mem_to_reg = 0;
        alu_op = 2'b00;
        mem_write = 0;
        alu_src = 0;
        reg_write = 0;
        is_lui = 0; 
        jump = 0; 
        mem_to_reg = 2'b00;

        case (opcode)
        // includes all types. Signals are set accordingly.
            7'b0100011: begin // SW
                alu_src   = 1; // Address = Reg + Imm
                mem_write = 1; // WRITE to memory
                alu_op    = 2'b00; // Force ADD (Address calculation)

            end
            7'b0000011: begin // LW
                alu_src    = 1; // Operand B comes from Imm
                mem_to_reg = 2'b01; // Data comes from Memory, not ALU
                reg_write  = 1;
                mem_read   = 1;
                alu_op     = 2'b00; // Force ADD (Address calculation)
            end
            7'b1100011: begin // Branch
                branch  = 1;
                alu_op  = 2'b01; // Force SUB (to compare A and B)
            end
            7'b0110011: begin // R-type
                reg_write = 1;
                alu_op    = 2'b10; // "10" tells ALU Decoder to look at funct3/7
            end
            // I-Type Arithmetic (ADDI)
            7'b0010011: begin // I-Type Arithmetic (ADDI, ANDI, ORI, etc.)
            alu_src   = 1; // Use Immediate
            reg_write = 1; 
            alu_op    = 2'b10;
            end

            // LUI (U-Type)
            7'b0110111: begin 
                reg_write = 1;
                alu_src = 1;    // Use Imm
                is_lui = 1;     // NEW: Tells Top Level to zero out Operand A
                alu_op = 2'b00; // Force ADD (0 + Imm)
            end

            // JAL (J-Type)
            7'b1101111: begin 
                jump = 1;           // NEW: Force PC Jump
                reg_write = 1;      // Write return address
                mem_to_reg = 2'b10; // NEW: Select PC+4 to write back
                // alu_op doesn't matter, we don't use ALU result
            end

            default: begin
                // default case: all control signals are already set to 0
            end
        endcase
    end
endmodule