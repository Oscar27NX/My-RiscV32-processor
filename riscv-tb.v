`timescale 1ns / 1ps

module riscv_tb;

    reg clk;
    reg rst;

    // Instantiate the Pipeline Processor
    // Note: connecting testbench 'rst' (active high) to processor 'rst_n' (active low)
    rv_pl uut (
        .clk(clk),
        .rst_n(~rst) 
    );

    // COUNTERS for CPI Calculation
    integer cnt_r_type = 0;
    integer cnt_i_type = 0;
    integer cnt_load   = 0;
    integer cnt_store  = 0;
    integer cnt_branch = 0;
    integer cnt_jal    = 0;
    integer cnt_jalr   = 0;
    integer cnt_lui    = 0;
    integer total_cycles = 0;
    
    integer total_instr = 0;

    // INSTRUCTION COUNTING LOGIC (Pipeline Adapted)
    // We sniff the instruction at the Decode Stage (D_instr).
    // We only count it if the stage is NOT stalled (re-reading same instr) 
    // and NOT flushed (killing bad instr).
    always @(posedge clk) begin
        if (rst) begin
            total_cycles = 0;
            cnt_r_type = 0; cnt_i_type = 0; cnt_load = 0; cnt_store = 0;
            cnt_branch = 0; cnt_jal = 0; cnt_jalr = 0; cnt_lui = 0;
        end else begin
            total_cycles = total_cycles + 1;

            // Check: Is there a valid instruction moving through Decode?
            // uut.F_stall == 0: We are not frozen (don't count same instr twice)
            // uut.D_flush == 0: We are not clearing this slot (don't count killed instr)
            if (!uut.F_stall && !uut.D_flush) begin
                case (uut.D_instr[6:0]) 
                    7'b0110011: cnt_r_type = cnt_r_type + 1; // R-Type
                    7'b0010011: cnt_i_type = cnt_i_type + 1; // I-Type (ADDI)
                    7'b0000011: cnt_load   = cnt_load   + 1; // LW
                    7'b0100011: cnt_store  = cnt_store  + 1; // SW
                    7'b1100011: cnt_branch = cnt_branch + 1; // BEQ
                    7'b1101111: cnt_jal    = cnt_jal    + 1; // JAL
                    7'b1100111: cnt_jalr   = cnt_jalr   + 1; // JALR
                    7'b0110111: cnt_lui    = cnt_lui    + 1; // LUI
                endcase
            end
        end
    end

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        $dumpfile("pipeline_wave.vcd");
        $dumpvars(0, riscv_tb);

        // 1. Initialize Memories
        // NOTE: Make sure your memory modules use 'reg [31:0] RAM' internally 
        // to match the Lab Manual requirements!
        $readmemh("program.hex", uut.IMEM.RAM); 
        
        // Initialize Data Memory to 0 (Optional, prevents 'x')
        for (integer k=0; k<256; k=k+1) begin
            uut.DMEM.RAM[k] = 32'b0;
        end

        // 2. Reset Sequence
        rst = 1;
        #20;
        @(negedge clk);
        rst = 0; // Release Reset

        // 3. Run Simulation
        // Increased time to account for pipeline latency and flush cycles
        #6000;

        // 4. Verification
        $display("-------------------------------------------------------------");
        $display("FINAL REGISTER STATE (Pipeline)");
        // Note: Using 'uut.RF.registers' based on your provided file names
        $display("x1 (Loop Count): %d", $signed(uut.RF.registers[1])); 
        $display("x2 (Limit):      %d", $signed(uut.RF.registers[2]));
        $display("x3 (Pointer):    %d", $signed(uut.RF.registers[3]));
        $display("x10 (Result):    %h", uut.RF.registers[10]);
        $display("-------------------------------------------------------------");
        
        $display("CHECKING MEMORY (Mem[0]..Mem[4])");
        // Accessing Data Memory directly
        $display("Addr 0:  %d", uut.DMEM.RAM[0]);
        $display("Addr 4:  %d", uut.DMEM.RAM[1]);
        $display("Addr 8:  %d", uut.DMEM.RAM[2]);
        $display("Addr 12: %d", uut.DMEM.RAM[3]);
        $display("Addr 16: %d", uut.DMEM.RAM[4]);
        
        $display("-------------------------------------------------------------");
        
        // Success Condition (Adjust 32'hdeadb000 if your program logic is different)
        if (uut.RF.registers[10] === 32'hdeadb000)
            $display("SUCCESS: Pipeline Processor Passed!");
        else
            $display("CHECK: Result is %h (Expected deadb000)", uut.RF.registers[10]);
        
        // 5. Performance Analysis (CPI)
        total_instr = cnt_r_type + cnt_i_type + cnt_load + cnt_store + cnt_branch + cnt_jal + cnt_jalr + cnt_lui;
        
        $display("\n--- PIPELINE CPI STATISTICS ---");
        $display("Total Cycles:       %0d", total_cycles);
        $display("Total Instructions: %0d", total_instr);
        // Avoid divide by zero
        if (total_instr > 0)
            $display("Average CPI:        %0.2f", $itor(total_cycles) / $itor(total_instr));
        else
            $display("Average CPI:        N/A");
            
        $display("-------------------------------");
        $display("Instruction Breakdown:");
        $display("R-Type: %0d", cnt_r_type);
        $display("I-Type: %0d", cnt_i_type);
        $display("LW:     %0d", cnt_load);
        $display("SW:     %0d", cnt_store);
        $display("BEQ:    %0d", cnt_branch);
        $display("JAL:    %0d", cnt_jal);
        $display("JALR:   %0d", cnt_jalr);
        $display("LUI:    %0d", cnt_lui);
        $display("-------------------------------");

        $finish;
    end
endmodule