// The program counter module

module MyProgramCounter #(parameter WIDTH = 32)(
    input wire clk,
    input wire rst,
    input [WIDTH-1:0] pc_in,
    output reg [WIDTH-1:0] pc_out
);

    // Synchronous process (sequential logic) to update the program counter
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= {WIDTH{1'b0}}; // Reset program counter to 0
        else
            pc_out <= pc_in; // Update program counter with input value
    end
endmodule