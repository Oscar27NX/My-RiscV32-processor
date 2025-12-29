// This unit receives the opcode to breakdwown control signals for the datapath
module Main_Decoder (
    input  wire [6:0] opcode,
    output reg       reg_write,
    output reg       mem_write,
    output reg       alu_src,    // 0 = RegB, 1 = Imm
    output reg [1:0] result_src, // 00=ALU, 01=Mem, 10=PC+4
    output reg       branch,
    output reg       jump,       // For JAL/JALR
    output reg [1:0] alu_op      // 00=Add, 01=Sub, 10=R-Type/Funct-based
);

    always @(*) begin
        // Defaults to prevent latches
        reg_write = 0; mem_write = 0; alu_src = 0; 
        result_src = 0; branch = 0; jump = 0; alu_op = 0;

        case (opcode)
            // R-Type (ADD, SUB, OR, etc.)
            7'b0110011: begin 
                reg_write = 1; 
                alu_op = 2'b10; // Tell ALU Decoder to look at Funct3
            end

            // I-Type Arithmetic (ADDI, etc.)
            7'b0010011: begin 
                reg_write = 1; 
                alu_src = 1;    // Use Immediate
                alu_op = 2'b10; // Use Funct3 (same as R-type usually)
            end

            // LW (Load Word)
            7'b0000011: begin 
                reg_write = 1; 
                alu_src = 1; 
                result_src = 2'b01; // Take from Memory
                alu_op = 2'b00;     // Force ADD (Base + Offset)
            end

            // SW (Store Word)
            7'b0100011: begin 
                mem_write = 1; 
                alu_src = 1; 
                alu_op = 2'b00;     // Force ADD
            end

            // BEQ (Branch)
            7'b1100011: begin 
                branch = 1; 
                alu_op = 2'b01;     // Force SUB (to compare)
            end

            // JAL (Jump)
            7'b1101111: begin 
                reg_write = 1;
                jump = 1; 
                result_src = 2'b10; // Store PC+4
            end

            default: ;
        endcase
    end
endmodule