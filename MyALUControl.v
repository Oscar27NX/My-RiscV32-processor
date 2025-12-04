module MyALUControl(
    input [1:0] alu_op,
    input [2:0] funct3,
    input funct7,
    output reg [3:0] alu_ctrl_in
);
    always @(*) begin
        case (alu_op)
            2'b00: alu_ctrl_in = 4'b0000; // LW, SW -> Force ADD 
            2'b01: alu_ctrl_in = 4'b0001; // BEQ -> Force SUB 
            2'b10: begin // R-type AND I-Type
                case (funct3)
                    3'b000: alu_ctrl_in = (funct7) ? 4'b0001 : 4'b0000; // SUB : ADD
                    3'b001: alu_ctrl_in = 4'b0010; // SLL / SLLI
                    3'b010: alu_ctrl_in = 4'b0100; // SLT
                    3'b011: alu_ctrl_in = 4'b0110; // SLTU
                    3'b100: alu_ctrl_in = 4'b1000; // XOR
                    3'b101: alu_ctrl_in = (funct7) ? 4'b1011 : 4'b1010; // SRA : SRL
                    3'b110: alu_ctrl_in = 4'b1100; // OR
                    3'b111: alu_ctrl_in = 4'b1110; // AND
                    default: alu_ctrl_in = 4'b0000;
                endcase
            end
            default: alu_ctrl_in = 4'b0000;
        endcase
    end
endmodule