`timescale 1ns / 1ps

module hazard_tb;
    reg clk;
    reg rst_n;

    // Instantiate the Pipelined Processor
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
        $dumpfile("hazard_wave.vcd");
        $dumpvars(0, hazard_tb);

        // 1. Load the Hazard Test Program
        $readmemh("hazard_program.hex", uut.IMEM.RAM);
        
        // 2. Clear Data Memory & RegFile (Optional but good for cleanliness)
        for (integer i=0; i<256; i=i+1) uut.DMEM.RAM[i] = 0;
        // Note: Registers clear on reset if logic implemented, otherwise rely on logic.

        // 3. Reset
        rst_n = 0;
        #20;
        rst_n = 1;

        // 4. Run Simulation
        // 13 instructions + stalls/flushes. 
        // 2000ns is plenty.
        #2000;

        $display("=============================================================");
        $display("               HAZARD UNIT VERIFICATION                      ");
        $display("=============================================================");

        // TEST 1: RAW Hazard (MEM Forwarding)
        // sub x2, x1, x0. x1 was forwarded from MEM.
        if (uut.RF.registers[2] === 10)
            $display("[PASS] RAW Hazard (MEM Forwarding): x2 = %d", $signed(uut.RF.registers[2]));
        else
            $display("[FAIL] RAW Hazard (MEM Forwarding): x2 = %d (Expected 10)", $signed(uut.RF.registers[2]));

        // TEST 2: RAW Hazard (WB Forwarding)
        // add x4, x3, x0. x3 was forwarded from WB.
        if (uut.RF.registers[4] === 20)
            $display("[PASS] RAW Hazard (WB Forwarding):  x4 = %d", $signed(uut.RF.registers[4]));
        else
            $display("[FAIL] RAW Hazard (WB Forwarding):  x4 = %d (Expected 20)", $signed(uut.RF.registers[4]));

        // TEST 3: Load-Use Hazard (Stall)
        // lw x5, then add x6, x5, x5. Stall inserted.
        if (uut.RF.registers[6] === 30)
            $display("[PASS] Load-Use Hazard (Stall):     x6 = %d", $signed(uut.RF.registers[6]));
        else
            $display("[FAIL] Load-Use Hazard (Stall):     x6 = %d (Expected 30)", $signed(uut.RF.registers[6]));

        // TEST 4: Control Hazard (Branch Flushing)
        // Branch taken. x7 instructions should be killed. x8 executed.
        if (uut.RF.registers[8] === 42) begin
            if (uut.RF.registers[7] === 0 || uut.RF.registers[7] === 32'bx) 
                $display("[PASS] Control Hazard (Flush):      x8 = 42, x7 = %d (Killed)", $signed(uut.RF.registers[7]));
            else
                $display("[FAIL] Control Hazard (Flush):      x7 = %d (Should be 0/x! Instruction wasn't flushed)", $signed(uut.RF.registers[7]));
        end else begin
            $display("[FAIL] Control Hazard (Branch):     x8 = %d (Expected 42 - Branch didn't take?)", $signed(uut.RF.registers[8]));
        end

        $display("=============================================================");
        $finish;
    end
endmodule