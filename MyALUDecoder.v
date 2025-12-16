module ALU_Decoder (
    input wire [1:0] ALUOp,      // 00=Add, 01=Sub, 10=R-type/I-type func
    input wire [2:0] funct3,
    input wire [6:0] funct7,
    input wire [6:0] opcode,    
    output reg [3:0] ALUControl  // 4-bit Control
);

    always @(*) begin
        case (ALUOp)
            2'b00: ALUControl = 4'b0000; // ADD (Used for LW, SW, PC+4)
            2'b01: ALUControl = 4'b0001; // SUB (Used for BEQ)
            
            2'b10: begin // R-Type or I-Type Logic
                case (funct3)
                    3'b000: begin // ADD or SUB
                        if (opcode == 7'b0110011 && funct7[5]) 
                            ALUControl = 4'b0001; // SUB
                        else 
                            ALUControl = 4'b0000; // ADD/ADDI
                    end
                    3'b001: ALUControl = 4'b0010; // SLL / SLLI
                    3'b010: ALUControl = 4'b0100; // SLT / SLTI
                    3'b011: ALUControl = 4'b0110; // SLTU / SLTIU
                    3'b100: ALUControl = 4'b1000; // XOR / XORI
                    3'b101: begin // SRL or SRA
                         if (funct7[5]) ALUControl = 4'b1011; // SRA / SRAI
                         else           ALUControl = 4'b1010; // SRL / SRLI
                    end
                    3'b110: ALUControl = 4'b1100; // OR / ORI
                    3'b111: ALUControl = 4'b1110; // AND / ANDI
                    default: ALUControl = 4'b0000;
                endcase
            end
            default: ALUControl = 4'b0000;
        endcase
    end
endmodule