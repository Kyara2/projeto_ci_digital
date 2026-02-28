`timescale 1ns / 1ps

module register_bank 
#(
    parameter INSTRUCTION_BITSIZE = 32,
    parameter REGISTER_ADDR_BITS = 5
)
(
	// entradas
    input wire clk,
    input wire reset,
    input wire register_enable_write,
    input wire [REGISTER_ADDR_BITS-1:0] register1_address,
    input wire [REGISTER_ADDR_BITS-1:0] register2_address,
    input wire [REGISTER_ADDR_BITS-1:0] register_address_to_write,
    input wire [INSTRUCTION_BITSIZE-1:0] register_data_to_write,

	input wire [REGISTER_ADDR_BITS-1:0] register_data_debug_address,
	
	// saidas
    output wire [INSTRUCTION_BITSIZE-1:0] register1_data,
    output wire [INSTRUCTION_BITSIZE-1:0] register2_data,
	
	
	output wire [INSTRUCTION_BITSIZE-1:0] register_data_debug
);

// banco dos registradores com 5 bits temos 2**5 = 32 registradores
reg [INSTRUCTION_BITSIZE-1:0] registers [0:(1<<REGISTER_ADDR_BITS)-1];

integer i;

// se for um reset limpa os registradores 
// caso contrario verifica se recebeu sinal de escrita do controle e escreve no registrador na borda do clock 
// tambem impede a escrita no registrador x0 que é sempre nulo
always @(posedge clk or posedge reset) begin
    if (reset) begin
        for (i = 0; i < (1<<REGISTER_ADDR_BITS); i = i + 1)
            registers[i] <= {INSTRUCTION_BITSIZE{1'b0}};
    end
    else if (register_enable_write && register_address_to_write != {REGISTER_ADDR_BITS{1'b0}})
        registers[register_address_to_write] <= register_data_to_write;
end

// le os registradores de modo asincrono 
assign register1_data =  
	(register1_address == 0) ? 0 : registers[register1_address];

assign register2_data =   
	(register1_address == 0) ? 0 : registers[register2_address];
	
// le um registrador especifico para debug
assign register_data_debug = 
	(register_data_debug_address == 0) ? 32'b0:
	registers[register_data_debug_address];

endmodule