// A new memory module, used to initialize instruction/data memory
// hence we avoid using initial blocks in synthesizable code.
module dmem #(parameter MEM_DEPTH = 256) (
    input wire clk,
    input wire we,
    input wire [31:0] addr,
    input wire [31:0] wd,
    output wire [31:0] rd
);

    reg [31:0] RAM [0 : MEM_DEPTH-1];
   
    // Synchronous Write
    always @(posedge clk) begin
        if (we)
            RAM[addr[31:2]] <= wd;
    end

    // Asynchronous Read
    assign rd = RAM[addr[31:2]];

endmodule