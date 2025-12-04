// Data memory module

module MyDataMemory (
    input wire clk,                   // Clock signal
    input wire mem_write,             // Memory write enable
    input wire [31:0] address,        // Memory address
    input wire [31:0] write_data,     // Data to write to memory
    output wire [31:0] read_data       // Data read from memory
);

    // Declare the data memory as an array of 256 words (32 bits each)
    // but why 256? because 2^8 = 256, and we are using 8 bits for addressing words in 32-bit words (4 bytes each)
    reg [31:0] memory [255:0];

    assign read_data = memory[address[31:2]]; // Word-aligned 

    integer i;

    // necessary to initialize memory to zero
    initial begin
        for (i=0; i<256; i=i+1)
            memory[i] = 0;
    end

    // Synchronous write operation
    always @(posedge clk) begin
        if (mem_write) begin
            memory[address[31:2]] <= write_data;
        end
    end
endmodule