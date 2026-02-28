`timescale 1ns / 1ps

module control_unit 
(

    input  wire [6:0] opcode,
    input  wire [2:0] funct3,
    input  wire [6:0] funct7,

    output reg        register_enable_write,
    output reg        mem_enable_read,
    output reg        mem_enable_write,
    output reg        mem_to_reg,
    output reg        alu_src,
    output reg        branch,
    output reg        jump,

    output reg        alu_src_a_pc,
    output reg [1:0]  wb_select,
    output reg [1:0]  next_pc_select,

    output reg [1:0]  memory_size,
    output reg        memory_sign_ext,
    output reg [3:0]  alu_control
);

always @(*) begin

    register_enable_write = 0;
    mem_enable_read       = 0;
    mem_enable_write      = 0;
    mem_to_reg            = 0;
    alu_src               = 0;
    branch                = 0;
    jump                  = 0;

    alu_src_a_pc          = 0;
    wb_select             = 2'b00;
    next_pc_select        = 2'b00;

    memory_size           = 2'b10;
    memory_sign_ext       = 1'b1;
    alu_control           = 4'b0000;

    case (opcode)

    // ================= R-Type =================
    7'b0110011: begin
        register_enable_write = 1;
        wb_select = 2'b00; // ALU
        case ({funct7, funct3})
            {7'b0000000,3'b000}: alu_control = 4'b0000;
            {7'b0100000,3'b000}: alu_control = 4'b0001;
            {7'b0000000,3'b001}: alu_control = 4'b0010;
            {7'b0000000,3'b010}: alu_control = 4'b0011;
            {7'b0000000,3'b011}: alu_control = 4'b0100;
            {7'b0000000,3'b100}: alu_control = 4'b0101;
            {7'b0000000,3'b101}: alu_control = 4'b0110;
            {7'b0100000,3'b101}: alu_control = 4'b0111;
            {7'b0000000,3'b110}: alu_control = 4'b1000;
            {7'b0000000,3'b111}: alu_control = 4'b1001;
        endcase
    end

    // ================= LOAD =================
    7'b0000011: begin
        register_enable_write = 1;
        mem_enable_read = 1;
        alu_src = 1;
        wb_select = 2'b01; // MEM
    end

    // ================= STORE =================
    7'b0100011: begin
        mem_enable_write = 1;
        alu_src = 1;
    end

    // ================= BRANCH =================
    7'b1100011: begin
        branch = 1;
        next_pc_select = 2'b01; // BRANCH
    end

    // ================= JAL =================
    7'b1101111: begin
        register_enable_write = 1;
        wb_select = 2'b10;       // PC+4
        next_pc_select = 2'b10;  // JAL
    end

    // ================= JALR =================
    7'b1100111: begin
        register_enable_write = 1;
        alu_src = 1;
        wb_select = 2'b10;       // PC+4
        next_pc_select = 2'b11;  // JALR
    end

    // ================= LUI =================
    7'b0110111: begin
        register_enable_write = 1;
        wb_select = 2'b11; // IMM
    end

    // ================= AUIPC =================
    7'b0010111: begin
        register_enable_write = 1;
        alu_src = 1;
        alu_src_a_pc = 1;
        wb_select = 2'b00;
        alu_control = 4'b0000;
    end

    endcase
end

endmodule