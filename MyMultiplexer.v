// 32-bit MUX from register file to ALU (2-to-1)
// parametrized for bit scalability
module MyMultiplexer #(parameter WIDTH = 32)(
    input wire sel,                   // Select signal
    input wire [WIDTH-1:0] b,      // Data from register file
    input wire [WIDTH-1:0] a,       // Data from program counter
    output wire [WIDTH-1:0] y       // Output to ALU
);
    assign y = (sel) ? a : b;
endmodule  