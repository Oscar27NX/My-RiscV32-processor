// Similar to Dmem, but RO (read-only)
// we use 2KB memory since it was enough for the lab python script
module Imem #(parameter MEM_DEPTH = 2048) (
    // we give ROM Bram direct access to clock and 
    // enable signal and flush; all of this so we can use as
    // fd register taking advantage of synchronous read and avoiding latency
    input wire clk,
    input wire en,
    input wire flush,
    input wire [31:0] addr,
    output wire [31:0] rd
);
    // Name the memory RAM as required
    reg [31:0] RAM [0 : MEM_DEPTH-1];
    
    // initiaize program if injected by the python script:
    initial begin
        $readmemh("program.mem", RAM);
    end

    always @(posedge clk) begin
        if (flush) begin
            // insert bubble, also sequential since it's BRAM
            rd <= 32'b0;
        end else if (en) begin
            rd <= RAM[addr[31:2]]; // 31:2 as 28 is multiple of 4
        end
    end
endmodule