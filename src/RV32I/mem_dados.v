`timescale 1ns / 1ps

module mem_dados (
    input  wire        sinal_clk,         // Clock do sistema 
    input  wire        habilitar_escrita, // Controle de escrita 
    input  wire [31:0] posicao_endereco,  // Endereço calculado pela ULA 
    input  wire [31:0] dado_entrada,      // Dado vindo do RD2 
    output wire [31:0] dado_leitura       // Dado lido para o RD 
);
    reg [31:0] ram_dados [0:255];         // Espaço de memória de dados [cite: 73]

    // Leitura assíncrona alinhada [cite: 73]
    assign dado_leitura = ram_dados[posicao_endereco[9:2]];

    // Escrita síncrona [cite: 73]
    always @(posedge sinal_clk) begin
        if (habilitar_escrita)
            ram_dados[posicao_endereco[9:2]] <= dado_entrada; // [cite: 74]
    end
endmodule