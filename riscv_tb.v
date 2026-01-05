`timescale 1ns / 1ps

module riscv_tb;
    reg clk;
    reg rst_n;
    integer cycle_count;
    
    // Instruction Count (17 lines - 2 flushed - 1 loop = 14)
    real instruction_count = 14.0; 

    rv_pl uut (
        .clk(clk),
        .rst_n(rst_n)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Cycle Counter
    always @(posedge clk) begin
        if (rst_n) cycle_count = cycle_count + 1;
    end

    always @(posedge clk) begin
        // If we fetch the infinite loop instruction we stop simulation
        if (uut.F_instr === 32'h00000063) begin

            // wait until the last stages are written back
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            @(posedge clk);
            
            $display("-------------------------------------------------------------");
            $display("BENCHMARK RESULTS");
            $display("-------------------------------------------------------------");
            $display("x1 (10):  %d", $signed(uut.RF.registers[1]));
            $display("x2 (10):  %d", $signed(uut.RF.registers[2]));
            $display("x3 (20):  %d", $signed(uut.RF.registers[3]));
            $display("x4 (10):  %d", $signed(uut.RF.registers[4]));
            $display("x5 (1):   %d", $signed(uut.RF.registers[5]));
            $display("x6 (15):  %d", $signed(uut.RF.registers[6]));
            $display("x7 (120): %d", $signed(uut.RF.registers[7]));
            $display("x8 (0):   %d", $signed(uut.RF.registers[8]));
            $display("x9 (255): %d", $signed(uut.RF.registers[9]));
            $display("x10(5):   %d", $signed(uut.RF.registers[10]));
            $display("x11(30):  %d", $signed(uut.RF.registers[11]));
            $display("-------------------------------------------------------------");
            $display("CPI Calculation (Performance Analysis):");
            $display("-------------------------------------------------------------");
            $display("Total Cycles: %d", cycle_count);
            $display("Instructions: %0d", instruction_count);
            $display("CPI: %f", cycle_count / instruction_count);
            $finish;
        end
    end

    initial begin
        $dumpfile("benchmark_wave.vcd");
        $dumpvars(0, riscv_tb);

        // Load the new Hex file
        $readmemh("program.hex", uut.IMEM.RAM);
        
        // Clear Memory before starting
        for (integer i=0; i<256; i=i+1) uut.DMEM.RAM[i] = 0;

        cycle_count = 0;
        rst_n = 0; 
        #20; 
        rst_n = 1;
        
        #2000 $finish; 
    end
endmodule