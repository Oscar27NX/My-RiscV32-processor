`timescale 1ns / 1ps

module independent_tb;
    reg clk;
    reg rst_n;

    // Instantiate your Pipelined Processor
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
        $dumpfile("independent_wave.vcd");
        $dumpvars(0, independent_tb);

        // 1. Load the Hex File
        // Make sure independent.hex is in the same folder!
        $readmemh("program.hex", uut.IMEM.RAM);
        
        // 2. Clear Data Memory (To ensure SW works)
        for (integer i=0; i<256; i=i+1) uut.DMEM.RAM[i] = 0;

        // 3. Reset Sequence
        rst_n = 0;
        #20;
        rst_n = 1;

        // 4. Run Simulation
        // We have 7 instructions + padding NOPs. 
        // 2500ns is plenty of time.
        #2500;

        $display("-------------------------------------------------------------");
        $display("INDEPENDENT INSTRUCTION TEST");
        $display("-------------------------------------------------------------");
        
        // CHECK 1: Initial Values
        $display("x1 (Expect 5):     %d", $signed(uut.RF.registers[1]));
        $display("x2 (Expect 7):     %d", $signed(uut.RF.registers[2]));

        // CHECK 2: Arithmetic (ADD)
        if (uut.RF.registers[3] === 12)
            $display("x3 (ADD):          %d [PASS]", $signed(uut.RF.registers[3]));
        else
            $display("x3 (ADD):          %d [FAIL] (Expected 12)", $signed(uut.RF.registers[3]));

        // CHECK 3: Arithmetic (SUB)
        if (uut.RF.registers[4] === 2)
            $display("x4 (SUB):          %d [PASS]", $signed(uut.RF.registers[4]));
        else
            $display("x4 (SUB):          %d [FAIL] (Expected 2)", $signed(uut.RF.registers[4]));

        // CHECK 4: Store Word (SW)
        // Mem Address 4 = Word Index 1
        if (uut.DMEM.RAM[1] === 12)
            $display("Mem[4] (SW):       %d [PASS]", uut.DMEM.RAM[1]);
        else
            $display("Mem[4] (SW):       %d [FAIL] (Expected 12)", uut.DMEM.RAM[1]);

        // CHECK 5: Load Word (LW)
        if (uut.RF.registers[5] === 12)
            $display("x5 (LW):           %d [PASS]", $signed(uut.RF.registers[5]));
        else
            $display("x5 (LW):           %d [FAIL] (Expected 12)", $signed(uut.RF.registers[5]));

        // CHECK 6: Logic (SLT)
        if (uut.RF.registers[6] === 1)
            $display("x6 (SLT):          %d [PASS]", $signed(uut.RF.registers[6]));
        else
            $display("x6 (SLT):          %d [FAIL] (Expected 1)", $signed(uut.RF.registers[6]));

        $finish;
    end
endmodule