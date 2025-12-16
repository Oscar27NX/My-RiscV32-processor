`timescale 1ns / 1ps

module riscv_tb;

    reg clk;
    reg rst;

    // Instantiate the Top Level Multicycle Processor
    MyMulticycleProcessor uut (
        .clk(clk),
        .rst(rst)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, riscv_tb);

        // --- 1. MEMORY INITIALIZATION ---
        // Load program into the NEW Instruction Memory (I_MEM)
        $readmemh("program.hex", uut.I_MEM.RAM); 
        
        // Initialize Data Memory (MEM) to 0 to avoid X
        // (Optional, but good for clean logs)
        // integer i;
        // for (i=0; i<256; i=i+1) uut.MEM.RAM[i] = 0;

        // --- 2. RESET SEQUENCE ---
        rst = 1;
        #20;
        @(negedge clk);
        rst = 0;

        // --- 3. RUN SIMULATION ---
        #6000;

        // --- 4. VERIFICATION ---
        $display("-------------------------------------------------------------");
        $display("FINAL REGISTER STATE");
        $display("x1 (Loop Count): %d", uut.Reg_File.registers[1]); 
        $display("x2 (Limit):      %d", uut.Reg_File.registers[2]);
        $display("x3 (Pointer):    %d", uut.Reg_File.registers[3]);
        $display("x10 (Result):    %h", uut.Reg_File.registers[10]);
        $display("-------------------------------------------------------------");
        
        // We still check uut.MEM for the results (Data)
        $display("CHECKING MEMORY (Mem[0]..Mem[4])");
        $display("Addr 0:  %d (Expect 20)", uut.MEM.RAM[0]);
        $display("Addr 4:  %d (Expect 22)", uut.MEM.RAM[1]);
        $display("Addr 8:  %d (Expect 24)", uut.MEM.RAM[2]);
        $display("Addr 12: %d (Expect 26)", uut.MEM.RAM[3]);
        $display("Addr 16: %d (Expect 28)", uut.MEM.RAM[4]);
        
        $display("-------------------------------------------------------------");
        
        if (uut.Reg_File.registers[10] === 32'hdeadb000 && uut.Reg_File.registers[1] === 5)
            $display(">>> SUCCESS: Multicycle Processor Passed! <<<");
        else
            $display(">>> FAILURE: Results mismatch. <<<");
        
        $finish;
    end
endmodule