`timescale 1ns / 1ps

module uart_full_duplex
#(
    // Parametros para o divisor de clock
    parameter CLK_FREQ = 12_000_000, // Frequencia do clock principal (12 MHz)
    parameter BAUD_RATE = 9_600    // Baud rate desejada de 9600
)
(
    input  wire clk,         // 12MHz na iCESugar
    input  wire reset_n,     // Reset (Geralmente pino do botão)
    input  wire rx,          // Entrada serial
    output wire tx,          // Saída serial
    
    // Interface para outros módulos
    output wire [7:0] data_received, 
    output wire rx_ready_tick,       // Pulsa quando um novo byte chega
    input  wire [7:0] data_to_send,  // Byte que seus módulos querem enviar
    input  wire tx_start_tick,       // Pulsa para iniciar envio
    output wire tx_busy              // Indica que o transmissor está ocupado
);

    wire reset = !reset_n;
    wire tx_done_internal;
    assign tx_busy = !tx_done_internal;

    // Sincronizador para o sinal RX (Proteção contra metaestabilidade)
    reg rx_sync_1, rx_sync_2;
    always @(posedge clk) begin
        rx_sync_1 <= rx;
        rx_sync_2 <= rx_sync_1;
    end

    // Instância do Receptor (Recebe do mundo externo)
    uart_receiver
	#(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE)
	)
	receiver (
        .clk(clk),
        .reset(reset),
        .rx(rx_sync_2),
        .data_out(data_received),
        .rx_done(rx_ready_tick)
    );

    // Instância do Transmissor (Envia para o mundo externo)
	uart_transmitter
	#(
		.CLK_FREQ(CLK_FREQ),
		.BAUD_RATE(BAUD_RATE)
	)
	transmitter (
        .clk(clk),
        .reset(reset),
        .data_in(data_to_send),
        .tx_start(tx_start_tick),
        .tx(tx),
        .tx_done(tx_done_internal)
    );

endmodule