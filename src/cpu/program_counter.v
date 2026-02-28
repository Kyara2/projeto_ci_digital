`timescale 1ns / 1ps

module program_counter 
#(
    parameter INSTRUCTION_BITSIZE = 32
)
(
    input  wire clk,
    input  wire reset,
    input  wire [INSTRUCTION_BITSIZE-1:0] pc_next,

    output reg  [INSTRUCTION_BITSIZE-1:0] pc_current
);

always @(posedge clk or posedge reset) begin
    if (reset)
        pc_current <= {INSTRUCTION_BITSIZE{1'b0}};
    else
        pc_current <= pc_next;
end

endmodule