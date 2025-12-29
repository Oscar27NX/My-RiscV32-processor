// The execute/memory register module
module EM_Register (
    input wire clk,
    input wire rst,
    input wire dmem_we_in,            // Input Data Memory Write Enable from EXE stage
    input wire [31:0] alu_out_in,     // Input ALU Output from EXE stage
    input wire [31:0] write_data_in,           // Input B value from EXE stage
    input wire [4:0] rd_in,
    input wire [1:0] sel_result_in,  // Input Result Select from EXE stage
    input wire rf_we_in,            // Input Register File Write Enable from EXE stage
    output reg dmem_we_out,           // Output Data Memory Write Enable to MEM stage
    output reg [31:0] alu_out_out,    // Output ALU Output to MEM stage
    output reg [31:0] write_data_out,          // Output B value to MEM stage
    output reg [4:0] rd_out,          // Output Destination Register to MEM stage
    output reg [1:0] sel_result_out,  // Output Result Select to MEM stage
    output reg rf_we_out             // Output Register File Write Enable to MEM stage
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dmem_we_out  <= 1'b0;
            alu_out_out  <= 32'b0;
            write_data_out        <= 32'b0;
            rd_out       <= 5'b0;
            sel_result_out <= 2'b0;
            rf_we_out    <= 1'b0;
        end else begin
            dmem_we_out  <= dmem_we_in;
            alu_out_out  <= alu_out_in;
            write_data_out        <= write_data_in;
            rd_out       <= rd_in;
            sel_result_out <= sel_result_in;
            rf_we_out    <= rf_we_in;
        end
    end
endmodule