`timescale 1ns / 1ps

module branch_unit 
#(parameter INSTRUCTION_BITSIZE = 32
)
(
	// inputs
    input  wire [2:0] funct3,
    input  wire [INSTRUCTION_BITSIZE-1:0] a,
    input  wire [INSTRUCTION_BITSIZE-1:0] b,
	
	// outputs
    output reg branch_taken
);

always @(*) begin
    case (funct3)

        3'b000: branch_taken = (a == b);                         // BEQ
        3'b001: branch_taken = (a != b);                         // BNE
        3'b100: branch_taken = ($signed(a) < $signed(b));        // BLT
        3'b101: branch_taken = ($signed(a) >= $signed(b));       // BGE
        3'b110: branch_taken = (a < b);                          // BLTU
        3'b111: branch_taken = (a >= b);                         // BGEU

        default: branch_taken = 1'b0;
    endcase
end

endmodule