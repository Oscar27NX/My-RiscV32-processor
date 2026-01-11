`timescale 1ns / 1ps

module pipelined_testbench;
    reg clk;
    reg rst_n;
    integer cycle_count;
    
    // Total instructions 12 total - 2 flushed = 10
    real instr_count = 10.0; 

    rv_pl uut (
        .clk(clk),
        .rst_n(rst_n)
    );

    // Clock
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Cycle Counter (i use it for CPI calculation)
    always @(posedge clk) begin
        if (rst_n) cycle_count = cycle_count + 1;
    end

    // ========================================================================
    // TEST PROCEDURE
    // ========================================================================
    initial begin
        $dumpfile("final_wave.vcd");
        $dumpvars(0, pipelined_testbench);

        // program initialization and reset
        $readmemh("final_test.hex", uut.IMEM.RAM);
        
        // Initializing Data Memory to 0
        for (integer i=0; i<256; i=i+1) uut.DMEM.RAM[i] = 0;

        // Reset Sequence
        cycle_count = 0;
        rst_n = 0; 
        #20; 
        rst_n = 1;

        // Run until Infinite Loop or Timeout
        wait (uut.F_instr === 32'h00000063);

        // waiting for pipeline to drain
        repeat (5) @(posedge clk);

        // ====================================================================
        // FINAL CHECK
        // ====================================================================
        $display("\n=============================================================");
        $display("PIPELINED PROCESSOR FINAL VERIFICATION        ");
        $display("=============================================================");
        
        // Check 1: Basic Arithmetic
        if ($signed(uut.RF.registers[3]) === 20) 
            $display("[PASS] Basic ADD:        x3 = 20");
        else 
            $display("[FAIL] Basic ADD:        x3 = %d (Expected 20)", $signed(uut.RF.registers[3]));

        // Check 2: Load-Use Hazard (Stall)
        // x5 loaded 20, then added 10 immediately. Result should be 30.
        // If stall failed, x5 would be 10 + garbage or old value.
        if ($signed(uut.RF.registers[5]) === 30) 
            $display("[PASS] Load-Use Stall:   x5 = 30");
        else 
            $display("[FAIL] Load-Use Stall:   x5 = %d (Expected 30)", $signed(uut.RF.registers[5]));

        // Check 3: RAW Hazard (Forwarding)
        // x4 = x3 - x2. x3 was forwarded. Result should be 10.
        if ($signed(uut.RF.registers[4]) === 10) 
            $display("[PASS] RAW Forwarding:   x4 = 10");
        else 
            $display("[FAIL] RAW Forwarding:   x4 = %d (Expected 10)", $signed(uut.RF.registers[4]));

        // Check 4: Branch Hazard (Flush)
        // x6 should be 1. If flush failed, x6 would be 15.
        if ($signed(uut.RF.registers[6]) === 1) 
            $display("[PASS] Branch Flush:     x6 = 1");
        else 
            $display("[FAIL] Branch Flush:     x6 = %d (Should be 1. If 15, flush failed)", $signed(uut.RF.registers[6]));

        $display("===============================================================");
        
        // Performance Analysis
        $display("Total Cycles: %0d", cycle_count);
        $display("Instruction Count: %0d", instr_count);
        $display("Calculated CPI: %0.2f", cycle_count / instr_count);
        
        $display("=============================================================\n");
        $finish;
    end
endmodule