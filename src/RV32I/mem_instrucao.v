`timescale 1ns / 1ps

module mem_instrucao(
    input  wire [31:0] barramento_endereco, // Endereço vindo do PC [cite: 75]
    output reg  [31:0] barramento_instrucao // Instrução de saída [cite: 75]
);
    reg [31:0] rom_interna [0:255];          // Memória de 256 palavras [cite: 76]
    integer k;

    initial begin
        // Inicializa toda a memória com NOP para satisfazer o sintetizador [cite: 85]
        for (k = 0; k < 256; k = k + 1)
            rom_interna[k] = 32'h00000013;   // Instrução NOP (ADDI x0, x0, 0) [cite: 85, 86]

        // Programa de teste carregado na memória [cite: 76]
        rom_interna[0] = 32'h00000093; // addi x1, x0, 0 [cite: 77]
        rom_interna[1] = 32'h00A00113; // addi x2, x0, 10 [cite: 78]
        rom_interna[2] = 32'h0020A023; // sw x2, 0(x1) [cite: 79]
        rom_interna[3] = 32'h0000A183; // lw x3, 0(x1) [cite: 80]
        rom_interna[4] = 32'h00310463; // beq x2, x3, +8 [cite: 81]
        rom_interna[5] = 32'h00118193; // addi x3, x3, 1 [cite: 82]
        rom_interna[6] = 32'h008000EF; // jal x1, +8 [cite: 83]
        rom_interna[7] = 32'h00120213; // addi x4, x4, 1 [cite: 84]
        rom_interna[8] = 32'h00500293; // addi x5, x0, 5 [cite: 85]
    end

    // Acesso alinhado à palavra para leitura [cite: 86]
    always @(*) begin
        barramento_instrucao = rom_interna[barramento_endereco[9:2]];
    end
endmodule