// the memory/writeback register module
module MW_Register (
    input wire clk,
    input wire rst_n,

    // --- Control Signals (In) ---
    // Memory controls consumed in MA. Only WB controls left.
    input wire [1:0] M_sel_result,
    input wire M_we_rf,

    // --- Data Signals (In) ---
    input wire [31:0] M_dm_rd,     // Data read from Memory
    input wire [31:0] M_alu_o,     // ALU Result (Bypassed Mem)
    input wire [4:0]  M_rf_a3,     // Destination Register Address
    input wire [31:0] M_pc_p4,

    // --- Outputs (Out to WB stage) ---
    output reg [1:0] W_sel_result,
    output reg W_we_rf,
    
    output reg [31:0] W_dm_rd,
    output reg [31:0] W_alu_o,
    output reg [4:0]  W_rf_a3,
    output reg [31:0] W_pc_p4
);

    always @(posedge clk) begin
        if (!rst_n) begin
            W_sel_result <= 2'b0;
            W_we_rf      <= 1'b0;
            W_dm_rd      <= 32'b0;
            W_alu_o      <= 32'b0;
            W_rf_a3      <= 5'b0;
            W_pc_p4      <= 32'b0;
        end else begin
            W_sel_result <= M_sel_result;
            W_we_rf      <= M_we_rf;
            W_dm_rd      <= M_dm_rd;
            W_alu_o      <= M_alu_o;
            W_rf_a3      <= M_rf_a3;
            W_pc_p4      <= M_pc_p4;
        end
    end
endmodule