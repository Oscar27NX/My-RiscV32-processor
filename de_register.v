module DE_Register (
    input wire clk, rst, clr,
    // Data
    input wire [31:0] rs1_data_in, rs2_data_in, imm_in, pc_in,
    input wire [4:0]  rd_in,
    // Control Signals (Generated in ID, used in EX/MEM/WB)
    input wire       rf_we_in, dmem_we_in, sel_src_b_in,
    input wire [1:0] sel_result_in,
    input wire [3:0] alu_control_in,

    // Outputs
    output reg [31:0] rs1_data_out, rs2_data_out, imm_out, pc_out,
    output reg [4:0]  rd_out,
    output reg        rf_we_out, dmem_we_out, sel_src_b_out,
    output reg [1:0]  sel_result_out,
    output reg [3:0]  alu_control_out
);
    always @(posedge clk or posedge rst) begin
        if (rst || clr) begin
             // Reset all to 0
             rf_we_out <= 0; dmem_we_out <= 0; /* etc... */
        end else begin
             rs1_data_out <= rs1_data_in;
             rf_we_out <= rf_we_in; // Pass the baton!
             /* assign all others */
        end
    end
endmodule