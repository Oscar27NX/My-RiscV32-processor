module InstructionRegister (
    input wire clk,
    input wire rst,
    input wire ir_write,        // Controlled by FSM
    input wire [31:0] mem_data, // From Memory
    output reg [31:0] instr     // To Controller and SignExt
);
    always @(posedge clk or posedge rst) begin
        if (rst) 
            instr <= 32'b0;
        else if (ir_write) 
            instr <= mem_data;
    end
endmodule