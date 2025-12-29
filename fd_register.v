// The FETCH/DECODE register module
module FD_Register (
    input wire clk,
    input wire rst,
    input wire en,
    input wire clr,
    input wire [31:0] pc_in,       // Input PC from PC Unit
    input wire [31:0] instr_in,    // Input Instruction from Instruction Memory
    output reg [31:0] pc_out,      // Output PC to next stage
    output reg [31:0] instr_out    // Output Instruction to next stage
);

    always @(posedge clk or posedge rst) begin
        if (rst || clr) begin
            pc_out    <= 32'b0;
            instr_out <= 32'b0;
        end else if (en) begin
            pc_out <= pc_in;
            instr_out <= instr_in;
        end
    end 
endmodule