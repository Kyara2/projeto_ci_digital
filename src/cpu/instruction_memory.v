`timescale 1ns / 1ps

module instruction_memory 
#(
    parameter INSTRUCTION_BITSIZE = 32,
	// precisa ser uma potencia de 2 <----
    parameter INSTRUCTION_MEMORY_DEPTH = 256 // menor tamanho para teste na fpga
)
(
	// entradas
	
	// endereço em bytes 
    input wire [INSTRUCTION_BITSIZE-1:0] instruction_address, 
	
	// saidas
    output wire [INSTRUCTION_BITSIZE-1:0] instruction_data
);

// registradores para a memoria de instrucao 
reg [INSTRUCTION_BITSIZE-1:0] memory [0:INSTRUCTION_MEMORY_DEPTH-1];

// endereco da palavra de memoria da instrução
wire [$clog2(INSTRUCTION_MEMORY_DEPTH)-1:0] word_address;

// Inicialização: preenche a memoria com  as instrucoes do arquivo no formato hexadecimal(sem o x ou h)
integer i;
initial begin
    // Preenche tudo com NOP (addi x0,x0,0)
	for (i = 0; i < INSTRUCTION_MEMORY_DEPTH; i = i + 1) begin
		memory[i] = 32'h00000013;
	end

    // Carrega programa
    $readmemh("program.hex", memory);
end


// le a instrucoes do endereco  fornecido apos obter a palavra associada a esse endereço
// cada instrução tem 4 bytes, então convertemos(divididimos por 4) endereço de memória para o indice da instrução na memória de instruções
assign word_address = instruction_address >> 2; 

assign instruction_data = memory[word_address];

endmodule