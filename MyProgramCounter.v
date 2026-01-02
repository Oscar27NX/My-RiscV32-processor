// Parametrized Program Counter Module, that simply updates its value on clock edge if enabled.
module MyProgramCounter #(parameter WIDTH = 32)(
    input wire clk,
    input wire rst,
    input wire en,            
    input [WIDTH-1:0] pc_in,
    output reg [WIDTH-1:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
            pc_out <= {WIDTH{1'b0}};
        else if (en)           
            pc_out <= pc_in;
    end
endmodule