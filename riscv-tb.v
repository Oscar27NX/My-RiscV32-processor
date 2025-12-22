`timescale 1ns / 1ps

module riscv_tb;

    reg clk;
    reg rst;

    // Instantiate the Top Level Multicycle Processor
    rv_mc uut (
        .clk(clk),
        .rst(rst)
    );

    // COUNTERS
    integer cnt_r_type = 0;
    integer cnt_i_type = 0;
    integer cnt_load   = 0;
    integer cnt_store  = 0;
    integer cnt_branch = 0;
    integer cnt_jal    = 0;
    integer cnt_lui    = 0;
    integer total_cycles = 0;

    // We check the Instruction Register (IR) every time the FSM is in the DECODE state (State 1).
    // This ensures we count each instruction exactly once per execution.
    always @(posedge clk) begin
        if (!rst) total_cycles = total_cycles + 1; 

        // Only count instruction when FSM enters DECODE state
        if (uut.Controller.FSM.state == 4'd1) begin
            case (uut.IR_Unit.instr[6:0]) 
                7'b0110011: cnt_r_type = cnt_r_type + 1; // R-Type
                7'b0010011: cnt_i_type = cnt_i_type + 1; // I-Type (ADDI)
                7'b0000011: cnt_load   = cnt_load   + 1; // LW
                7'b0100011: cnt_store  = cnt_store  + 1; // SW
                7'b1100011: cnt_branch = cnt_branch + 1; // BEQ
                7'b1101111: cnt_jal    = cnt_jal    + 1; // JAL
                7'b0110111: cnt_lui    = cnt_lui    + 1; // LUI
            endcase
        end
    end

    // Clock Generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Test Sequence
    initial begin
        $dumpfile("cpu_wave.vcd");
        $dumpvars(0, riscv_tb);

        // IMPORTANT. Memory is not initialized as 0. If you don't wanna see "don't care bits" (x) then just uncomment this:
        // for (i = 0; i < 32; i = i + 1) begin
        //    uut.Reg_File.registers[i] = 32'b0;
        // end
        // Load program into the Instruction Memory
        $readmemh("program.hex", uut.I_MEM.RAM); 

        // RESET SEQUENCE
        rst = 1;
        #20;
        @(negedge clk);
        rst = 0;

        // RUN SIMULATION 
        #6000;

        // VERIFICATION
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
            $display("SUCCESS: Multicycle Processor Passed!");
        else
            $display("FAILURE: Results mismatch. DDD:");
        
        // Used to solve section 4.2; performance analysis and fill the table.
        $display("\n--- CPI STATISTICS TABLE ---");
        $display("Type      | Cycles | Count");
        $display("----------|--------|------");
        $display("R-Type    | 4      | %0d", cnt_r_type);
        $display("I-Type    | 4      | %0d", cnt_i_type);
        $display("LW        | 5      | %0d", cnt_load);
        $display("SW        | 4      | %0d", cnt_store);
        $display("BEQ       | 3      | %0d", cnt_branch);
        $display("JAL       | 3      | %0d", cnt_jal);
        $display("LUI       | 4      | %0d", cnt_lui);
        $display("--------------------------");
        $display("Total Instr: %0d", (cnt_r_type+cnt_i_type+cnt_load+cnt_store+cnt_branch+cnt_jal+cnt_lui));
        $display("Total Cycles: %0d", total_cycles);
        $display("--------------------------");

        $finish;
    end
endmodule
