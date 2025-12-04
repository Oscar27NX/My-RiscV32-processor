`timescale 1ns / 1ps

module RISCV_tb;

    reg clk;
    reg rst;

    MyProcessor uut (
        .clk(clk),
        .rst(rst)
    );

    // clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // test Sequence
    initial begin
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, RISCV_tb);

        // hard reset sequence
        rst = 1;
        #20;          // delay for 20 (time) units
        @(negedge clk); // Wait for a falling edge 
        rst = 0;      

        #2500;        // Run

        // testing results

        $display("FINAL REGISTER STATE");
        $display("x1 (Loop Count): %d", uut.Reg_File.registers[1]);
        $display("x2 (Limit):      %d", uut.Reg_File.registers[2]);
        $display("x3 (Pointer):    %d", uut.Reg_File.registers[3]);
        $display("x10 (Result):    %h", uut.Reg_File.registers[10]);

        
        // check mem values
        $display("CHECKING MEMORY (Mem[0]..Mem[4])");
        // We use a loop to print them, verifying x3 actually moved
        $display("Addr 0: %d", uut.Data_Mem.memory[0]);
        $display("Addr 4: %d", uut.Data_Mem.memory[1]);
        $display("Addr 8: %d", uut.Data_Mem.memory[2]);
        $display("Addr 12: %d", uut.Data_Mem.memory[3]);
        $display("Addr 16: %d", uut.Data_Mem.memory[4]);
        
        if (uut.Reg_File.registers[10] === 32'hdeadb000)
            $display("PASSED!!!!");
        else
            $display("FAILURE D:");
        
        $finish;
    end

endmodule