// 32-bit MUX from register file to ALU (2-to-1)
// parametrized for bit scalability
module MyMultiplexer #(parameter WIDTH = 32)(
    input wire sel,                   // Select signal
    input wire [WIDTH-1:0] reg_data,      // Data from register file
    input wire [WIDTH-1:0] sign_ext,       // Data from program counter
    output wire [WIDTH-1:0] mux_out       // Output to ALU
);
    assign mux_out = (sel) ? sign_ext : reg_data;
endmodule  