`timescale 1ns / 1ps

module cpu_riscv 
	#(
	parameter DATA_MEMORY_DEPTH = 256,
	parameter INSTRUCTION_MEMORY_DEPTH = 256,
	
    parameter INSTRUCTION_BITSIZE = 32,
    parameter REGISTER_ADDR_BITS  = 5,
    parameter OPCODE_SIZE         = 7,
    parameter ENABLE_DEBUG        = 1)
	(
    input  wire clk,
    input  wire reset,

    input  wire [REGISTER_ADDR_BITS-1:0] register_data_debug_address,
    output wire [INSTRUCTION_BITSIZE-1:0] register_data_debug
);

//
// ========================
// PROGRAM COUNTER
// ========================
//
wire [31:0] pc_current;
wire [31:0] pc_next;

program_counter pc (
    .clk(clk),
    .reset(reset),
    .pc_next(pc_next),
    .pc_current(pc_current)
);

wire [31:0] pc_plus_4 = pc_current + 32'd4;

//
// ========================
// INSTRUCTION MEMORY
// ========================
//
wire [31:0] instruction;

instruction_memory #(.INSTRUCTION_MEMORY_DEPTH(INSTRUCTION_MEMORY_DEPTH)) imem (
    .instruction_address(pc_current),
    .instruction_data(instruction)
);

//
// ========================
// DECODE FIELDS
// ========================
//
wire [4:0] rs1 = instruction[19:15];
wire [4:0] rs2 = instruction[24:20];
wire [4:0] rd  = instruction[11:7];

wire [6:0] opcode = instruction[6:0];
wire [2:0] funct3 = instruction[14:12];
wire [6:0] funct7 = instruction[31:25];

//
// ========================
// REGISTER FILE
// ========================
//
wire [31:0] register1_data;
wire [31:0] register2_data;
wire [31:0] register_data_to_write;
wire register_enable_write;

generate
if (ENABLE_DEBUG) begin
    register_bank regbank (
        .clk(clk),
        .reset(reset),
        .register_enable_write(register_enable_write),
        .register1_address(rs1),
        .register2_address(rs2),
        .register_address_to_write(rd),
        .register_data_to_write(register_data_to_write),
        .register1_data(register1_data),
        .register2_data(register2_data),
        .register_data_debug_address(register_data_debug_address),
        .register_data_debug(register_data_debug)
    );
end else begin
    register_bank regbank (
        .clk(clk),
        .reset(reset),
        .register_enable_write(register_enable_write),
        .register1_address(rs1),
        .register2_address(rs2),
        .register_address_to_write(rd),
        .register_data_to_write(register_data_to_write),
        .register1_data(register1_data),
        .register2_data(register2_data)
    );
    assign register_data_debug = 32'b0;
end
endgenerate

//
// ========================
// IMMEDIATE GENERATOR
// ========================
//
wire [31:0] immediate;

immediate_generator imm_gen (
    .instruction(instruction),
    .immediate(immediate)
);

//
// ========================
// CONTROL UNIT
// ========================
//
wire mem_enable_read;
wire mem_enable_write;
wire mem_to_reg;
wire alu_src;
wire branch;
wire jump;

wire alu_src_a_pc;
wire [1:0] wb_select;
wire [1:0] next_pc_select;

wire [1:0] memory_size;
wire memory_sign_ext;
wire [3:0] alu_control;

control_unit control (
    .opcode(opcode),
    .funct3(funct3),
    .funct7(funct7),
    .register_enable_write(register_enable_write),
    .mem_enable_read(mem_enable_read),
    .mem_enable_write(mem_enable_write),
    .mem_to_reg(mem_to_reg),
    .alu_src(alu_src),
    .branch(branch),
    .jump(jump),

    .alu_src_a_pc(alu_src_a_pc),
    .wb_select(wb_select),
    .next_pc_select(next_pc_select),

    .memory_size(memory_size),
    .memory_sign_ext(memory_sign_ext),
    .alu_control(alu_control)
);

//
// ========================
// ALU
// ========================
//
wire [31:0] alu_operand1;
wire [31:0] alu_operand2;
wire [31:0] alu_result;
wire zero_flag;

// AUIPC usa PC como operando A
assign alu_operand1 =
    alu_src_a_pc ? pc_current :
                   register1_data;

assign alu_operand2 =
    alu_src ? immediate : register2_data;

alu alu_core (
    .a(alu_operand1),
    .b(alu_operand2),
    .alu_control(alu_control),
    .result(alu_result),
    .zero(zero_flag)
);

//
// ========================
// DATA MEMORY
// ========================
//
wire [31:0] memory_data_read;
wire misaligned_exception;

data_memory #(.DATA_MEMORY_DEPTH(DATA_MEMORY_DEPTH)) dataMem (
    .clk(clk),
    .memory_enable_write(mem_enable_write),
    .memory_enable_read(mem_enable_read),
    .memory_size(memory_size),
    .memory_sign_ext(memory_sign_ext),
    .memory_address(alu_result),
    .memory_data_to_write(register2_data),
    .memory_data_read(memory_data_read),
    .misaligned_exception(misaligned_exception)
);

//
// ========================
// BRANCH UNIT
// ========================
//
wire branch_taken;

branch_unit brancher (
    .funct3(funct3),
    .a(register1_data),
    .b(register2_data),
    .branch_taken(branch_taken)
);

//
// ========================
// WRITE BACK
// ========================
//
assign register_data_to_write =
    (wb_select == 2'b00) ? alu_result :
    (wb_select == 2'b01) ? memory_data_read :
    (wb_select == 2'b10) ? pc_plus_4 :
                           immediate;
//
// ========================
// NEXT PC LOGIC
// ========================
//
wire [31:0] branch_target = pc_current + immediate;
wire [31:0] jal_target    = pc_current + immediate;
wire [31:0] jalr_target   = (register1_data + immediate) & 32'hFFFFFFFE;

assign pc_next =
    (next_pc_select == 2'b11) ? jalr_target :
    (next_pc_select == 2'b10) ? jal_target  :
    (next_pc_select == 2'b01 && branch_taken) ? branch_target :
                                                pc_plus_4;
												
endmodule