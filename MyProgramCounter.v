// Parametrized Program Counter Module, that simply updates its value on clock edge when enabled
module ProgramCounter #(parameter WIDTH = 32)(
    input wire clk,
    input wire rst,
    input wire en,            
    input [WIDTH-1:0] pc_in,
    output reg [WIDTH-1:0] pc_out
);
    always @(posedge clk or posedge rst) begin
        if (rst)
        // updates 32 bit (4 byte-aligned) PC value
            pc_out <= {WIDTH{1'b0}};
        else if (en)           
            pc_out <= pc_in;
    end
endmodule