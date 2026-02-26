`timescale 1ns / 1ps

module pc_reg (
    input  wire        sinal_clk,   // Clock do sistema 
    input  wire        sinal_rst,   // Reset assíncrono 
    input  wire [31:0] entrada_pc,  // Próximo endereço calculado 
    output reg  [31:0] saida_pc     // Endereço atual do PC 
);
    always @(posedge sinal_clk or posedge sinal_rst) begin
        if (sinal_rst)
            saida_pc <= 32'd0;      // Reinicia no endereço zero [cite: 88]
        else
            saida_pc <= entrada_pc; // Atualiza para o próximo PC [cite: 89]
    end
endmodule