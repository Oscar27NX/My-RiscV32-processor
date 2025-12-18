// The 32-bit register file module

module MyRegisterFile #(parameter WIDTH = 32)(
    input clk,                  
    input wire [4:0] rs1_sel,    
    input wire [4:0] rs2_sel,    
    input wire [4:0] rd_reg,     
    input wire [WIDTH-1:0] write_data,    
    input wire reg_write,            
    output wire [WIDTH-1:0] read_data1,   
    output wire [WIDTH-1:0] read_data2    
);

    // Declare the register file as an array of 32 registers, each 32 bits wide in RISCV32
    reg [WIDTH-1:0] registers [0:31];

    // Read operations (combinational logic)
    assign read_data1 = (rs1_sel == 5'b0) ? {WIDTH{1'b0}} : registers[rs1_sel];
    assign read_data2 = (rs2_sel == 5'b0) ? {WIDTH{1'b0}} : registers[rs2_sel];
    // Need this, otherwise, longer simulations may have X values
    integer i;

    // Write operation (synchronous)
    always @(posedge clk) begin
        if (reg_write && (rd_reg != 5'b0)) begin
            registers[rd_reg] <= write_data;
        end
    end
endmodule