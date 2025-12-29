// the memory/writeback register module
module MW_Register (
    input wire clk,
    input wire rst,
    input wire rf_we_in,            // Input Register File Write Enable from MEM stage
    input wire [31:0] mem_data_in,  // Input Memory Data from MEM stage
    input wire [1:0] sel_result_in, // Input Result Select from MEM stage
    input wire [31:0] alu_out_in,   // Input ALU Output from MEM stage
    input wire [4:0] rd_in,         // Input Destination Register from MEM stage
    output reg rf_we_out,           // Output Register File Write Enable to WB stage
    output reg [31:0] mem_data_out, // Output Memory Data to WB stage
    output reg [31:0] alu_out_out,  // Output ALU Output to WB stage
    output reg [1:0] sel_result_out, // Output Result Select to WB stage
    output reg [4:0] rd_out         // Output Destination Register to WB stage
);  

    // sequential logic update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            rf_we_out      <= 1'b0;
            mem_data_out   <= 32'b0;
            alu_out_out    <= 32'b0;
            rd_out         <= 5'b0;
            sel_result_out <= 2'b0;
        end else begin
            rf_we_out      <= rf_we_in;
            mem_data_out   <= mem_data_in;
            alu_out_out    <= alu_out_in;
            rd_out         <= rd_in;
            sel_result_out <= sel_result_in;
        end
    end
endmodule