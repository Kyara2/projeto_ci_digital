`timescale 1ns / 1ps

module immediate_generator
#(
    parameter INSTRUCTION_BITSIZE = 32,
    parameter OPCODE_SIZE = 7
)
(
    // inputs
    input  [INSTRUCTION_BITSIZE-1:0] instruction,

    // outputs
    output reg [INSTRUCTION_BITSIZE-1:0] immediate
);

    // Extract opcode
    wire [OPCODE_SIZE-1:0] opcode;
    assign opcode = instruction[OPCODE_SIZE-1:0];

    always @(*) begin
        case (opcode)

            // =========================
            // I-Type (ADDI, ANDI, ORI, LW, JALR)
            // opcode: 0010011, 0000011, 1100111
            // =========================
            7'b0010011,
            7'b0000011,
            7'b1100111:
                immediate = {{20{instruction[31]}}, instruction[31:20]};

            // =========================
            // S-Type (SW)
            // opcode: 0100011
            // =========================
            7'b0100011:
                immediate = {{20{instruction[31]}},
                             instruction[31:25],
                             instruction[11:7]};

            // =========================
            // B-Type (BEQ, BNE, BLT, BGE)
            // opcode: 1100011
            // =========================
            7'b1100011:
                immediate = {{19{instruction[31]}},
                             instruction[31],
                             instruction[7],
                             instruction[30:25],
                             instruction[11:8],
                             1'b0};

            // =========================
            // U-Type (LUI, AUIPC)
            // opcode: 0110111, 0010111
            // =========================
            7'b0110111,
            7'b0010111:
                immediate = {instruction[31:12], 12'b0};

            // =========================
            // J-Type (JAL)
            // opcode: 1101111
            // =========================
            7'b1101111:
                immediate = {{11{instruction[31]}},
                             instruction[31],
                             instruction[19:12],
                             instruction[20],
                             instruction[30:21],
                             1'b0};

            default:
                immediate = {INSTRUCTION_BITSIZE{1'b0}};

        endcase
    end

endmodule