// The execute/memory register module
module EM_Register (input wire clk,
    input wire rst_n,

    // --- Control Signals (In) ---
    // Note: ALU controls and Branch/Jump are consumed in EX, so they stop here.
    // We only pass down Mem and WB controls.
    input wire [1:0] E_sel_result,
    input wire E_we_dm,
    input wire E_we_rf,

    // --- Data Signals (In) ---
    input wire [31:0] E_alu_o,     // ALU Result (Address for Mem)
    input wire [31:0] E_dm_wd,     // Data to write to Mem (usually r2)
    input wire [4:0]  E_rf_a3,     // Destination Register Address
    input wire [31:0] E_pc_p4,

    // --- Outputs (Out to MA stage) ---
    output reg [1:0] M_sel_result,
    output reg M_we_dm,
    output reg M_we_rf,
    
    output reg [31:0] M_alu_o,
    output reg [31:0] M_dm_wd,
    output reg [4:0]  M_rf_a3,
    output reg [31:0] M_pc_p4
);

    always @(posedge clk) begin
        if (!rst_n) begin
            M_sel_result <= 2'b0;
            M_we_dm      <= 1'b0;
            M_we_rf      <= 1'b0;
            M_alu_o      <= 32'b0;
            M_dm_wd      <= 32'b0;
            M_rf_a3      <= 5'b0;
            M_pc_p4      <= 32'b0;
        end else begin
            M_sel_result <= E_sel_result;
            M_we_dm      <= E_we_dm;
            M_we_rf      <= E_we_rf;
            M_alu_o      <= E_alu_o;
            M_dm_wd      <= E_dm_wd;
            M_rf_a3      <= E_rf_a3;
            M_pc_p4      <= E_pc_p4;
        end
    end
endmodule
