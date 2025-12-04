// The instruction memory module

module MyInstructionMemory (
    input wire [31:0] address,       
    output wire [31:0] instruction     
);

    // again, declare the instruction memory as an array of 256 words (32 bits each)
    reg [31:0] mem [0:255];

    // correct word alignment
    assign instruction = mem[address[31:2]]; 

    initial begin
        // program.hex will always be our test program! (can change the file in the directory, but keep the name)
        // logically not synthesizable, but it is necessary for the simulation
        $readmemh("program.hex", mem);
    end
endmodule