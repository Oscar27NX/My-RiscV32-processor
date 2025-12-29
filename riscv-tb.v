`timescale 1ns / 1ps

module debug_tb;

    reg clk;
    reg rst;

    // Instantiate the Processor
    rv_mc uut (
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
        $dumpfile("debug_wave.vcd");
        $dumpvars(0, debug_tb);

        // --- 1. LOAD PROGRAM ---
        $readmemh("program.hex", uut.I_MEM.RAM);

        // --- 2. RESET ---
        rst = 1;
        #20;
        @(negedge clk); 
        rst = 0;

        // --- 3. RUN SIMULATION ---
        // 11 instructions. Give plenty of time.
        #2000;

        // --- 4. VERIFICATION ---
        $display("\n-------------------------------------------------------------");
        $display("DEBUG PROGRAM RESULTS");
        $display("-------------------------------------------------------------");
        
        // 1. ADDI x5, x0, 10
        $display("x5 (Immediate 10):      %d (Expect 10)", $signed(uut.Reg_File.registers[5]));

        // 2. ADDI x6, x0, -5
        $display("x6 (Immediate -5):      %d (Expect -5)", $signed(uut.Reg_File.registers[6]));

        // 3. OR x7, x5, x6  -> (10 | -5) = -5
        $display("x7 (OR Result):         %d (Expect -5)", $signed(uut.Reg_File.registers[7]));
        
        // 4. SW x7, 0(x0)   -> Mem[0] should be -5
        $display("Mem[0] (Store x7):      %d (Expect -5)", $signed(uut.MEM.RAM[0]));

        // 5. ADDI x8, x5, 20 -> 10 + 20 = 30
        $display("x8 (10 + 20):           %d (Expect 30)", $signed(uut.Reg_File.registers[8]));

        // 6. ADD x9, x8, x7 -> 30 + (-5) = 25
        $display("x9 (30 + -5):           %d (Expect 25)", $signed(uut.Reg_File.registers[9]));

        // 7. SW x9, 4(x0)   -> Mem[4] (Index 1) should be 25
        $display("Mem[4] (Store x9):      %d (Expect 25)", $signed(uut.MEM.RAM[1]));

        // 8. BEQ x9, x5, +8 -> (25 == 10)? False. Should NOT take branch.
        // If it failed and took the branch, x10 would remain 0 (or x).
        // Since it continues, x10 gets written in step 9.

        // 9. ADDI x10, x0, 1
        $display("x10 (Branch Skipped?):  %d (Expect 1)", $signed(uut.Reg_File.registers[10]));

        // 10. ADDI x11, x0, 123
        $display("x11 (Final Value):      %d (Expect 123)", $signed(uut.Reg_File.registers[11]));

        $display("-------------------------------------------------------------");

        if (uut.Reg_File.registers[5] === 10 && 
            uut.Reg_File.registers[6] === -5 &&
            uut.Reg_File.registers[7] === -5 &&
            uut.MEM.RAM[0] === -5 && // Check Memory Word 0
            uut.Reg_File.registers[8] === 30 &&
            uut.Reg_File.registers[9] === 25 &&
            uut.MEM.RAM[1] === 25 && // Check Memory Word 1 (Addr 4)
            uut.Reg_File.registers[10] === 1 &&
            uut.Reg_File.registers[11] === 123) 
        begin
            $display(">>> SUCCESS: Debug Program Passed! <<<");
        end else begin
            $display(">>> FAILURE: Values did not match expectations. <<<");
        end
        
        $finish;
    end
endmodule