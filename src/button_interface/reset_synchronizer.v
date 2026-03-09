`timescale 1ns / 1ps

module reset_synchronizer
(
    input  wire clk,                   // clock do sistema
    input  wire button_reset_pressed,  // reset assíncrono (botão)
    output wire reset                  // reset síncrono para o sistema
);

    // registradores do sincronizador
    reg [1:0] sync_reg;
	
	// evita metaestabilidade permitindo os outros modulos utilizarem apenas reset sincrono sem risco
	// garantindo assim que o reset fique ativo por 2 ciclos do clock apos o botao de reset ser solto
    always @(posedge clk or posedge button_reset_pressed) begin
        if (button_reset_pressed)
            sync_reg <= 2'b11;  // força reset imediatamente
        else
            sync_reg <= {sync_reg[0], 1'b0}; // desloca até liberar reset
    end

    assign reset = sync_reg[1];

endmodule