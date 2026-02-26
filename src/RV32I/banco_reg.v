`timescale 1ns / 1ps

module banco_reg(
    input  wire        sinal_clk,        // Clock para escrita síncrona [cite: 90]
    input  wire [4:0]  sel_reg1,         // Seletor RS1 [cite: 90]
    input  wire [4:0]  sel_reg2,         // Seletor RS2 [cite: 90]
    output wire [31:0] dado_saida1,      // Saída RD1 [cite: 90]
    output wire [31:0] dado_saida2,      // Saída RD2 [cite: 90]
    input  wire [4:0]  reg_destino,      // Registrador de destino RD [cite: 90]
    input  wire [31:0] dado_escrita,     // Dado a ser gravado WD [cite: 90]
    input  wire        habilitar_escrita // Write Enable [cite: 91]
);
    reg [31:0] registros [0:31];         // Array de 32 registros [cite: 91]
    integer j;

    initial begin
        for (j = 0; j < 32; j = j + 1)
            registros[j] = 32'd0;        // Inicialização para simulação [cite: 93]
    end

    // Leituras combinacionais (x0 é sempre zero) [cite: 94, 95]
    assign dado_saida1 = (sel_reg1 == 5'd0) ? 32'd0 : registros[sel_reg1];
    assign dado_saida2 = (sel_reg2 == 5'd0) ? 32'd0 : registros[sel_reg2];

    // Escrita síncrona na borda de subida [cite: 96]
    always @(posedge sinal_clk) begin
        if (habilitar_escrita && reg_destino != 5'd0)
            registros[reg_destino] <= dado_escrita; // [cite: 97]
    end
endmodule