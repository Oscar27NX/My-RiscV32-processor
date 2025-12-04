// the sign extension module for immediate values in RISC-V instructions

module MySignExt(
    input [31:0] instruction,
    output reg [31:0] imm_out
);

    wire [6:0] opcode;
    assign opcode = instruction[6:0];

    always @(*) begin
        case (opcode)
            // I-Type (LW) and I-Type Arithmetic (ADDI)
            7'b0000011, 7'b0010011: begin 
                // Sign-extend bit 31 to the top 20 bits, then take instr[31:20]
                imm_out = {{20{instruction[31]}}, instruction[31:20]};
            end

            7'b0100011: // SW
            begin
                // S-type immediate
                imm_out = {{20{instruction[31]}}, instruction[31:25], instruction[11:7]};
            end

            7'b1100011: // Branch
            begin
                // B-type immediate
                imm_out = {{20{instruction[31]}}, instruction[7], instruction[30:25], instruction[11:8], 1'b0};
            end

            7'b1101111: // JAL
            begin
                // J-type immediate
                imm_out = {{12{instruction[31]}}, instruction[19:12], instruction[20], instruction[30:21], 1'b0};
            end

            // LUI (U-Type)
            7'b0110111: begin
                imm_out = {instruction[31:12], 12'b0};
            end

            default:
            begin
                imm_out = 32'b0; // Default case
            end
        endcase
    end
endmodule