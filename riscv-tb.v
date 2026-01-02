`timescale 1ns / 1ps

module debug_tb;
    reg clk;
    reg rst_n;

    // Instantiate your Pipeline
    rv_pl uut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        $dumpfile("memory_wave.vcd");
        $dumpvars(0, debug_tb);

        // 1. Load the Memory Test Program
        $readmemh("program.hex", uut.IMEM.RAM);
        
        // 2. Clear Data Memory (To verify SW actually writes)
        for (integer i=0; i<256; i=i+1) uut.DMEM.RAM[i] = 0;

        // 3. Reset
        rst_n = 0;
        #20;
        rst_n = 1;

        // 4. Run Simulation
        #2500;

        $display("-------------------------------------------------------------");
        $display("MEMORY TEST RESULTS (Pre-Hazard Unit)");
        $display("-------------------------------------------------------------");
        
        // CHECK 1: Setup Registers
        $display("x1 (Addr 40):   %d", $signed(uut.RF.registers[1]));
        $display("x2 (Data 99):   %d", $signed(uut.RF.registers[2]));

        // CHECK 2: Store Word (SW)
        // Address 40 corresponds to Word Index 10 (40 / 4 = 10)
        if (uut.DMEM.RAM[10] === 99)
            $display("Mem[40] (SW):   %d [PASS]", uut.DMEM.RAM[10]);
        else
            $display("Mem[40] (SW):   %d [FAIL] (Expected 99)", uut.DMEM.RAM[10]);

        // CHECK 3: Load Word (LW)
        if (uut.RF.registers[3] === 99)
            $display("x3 (LW Result): %d [PASS]", $signed(uut.RF.registers[3]));
        else
            $display("x3 (LW Result): %d [FAIL] (Expected 99 from Load)", $signed(uut.RF.registers[3]));

        // CHECK 4: Read After Load
        // This ensures the loaded value was actually usable by the ALU
        if (uut.RF.registers[4] === 100)
            $display("x4 (x3 + 1):    %d [PASS]", $signed(uut.RF.registers[4]));
        else
            $display("x4 (x3 + 1):    %d [FAIL] (Expected 100)", $signed(uut.RF.registers[4]));

        $finish;
    end
endmodule