`timescale 1ns / 1ps

module uart_top_tb();

    // Sinais de Entrada do Top
    reg clk;
    reg reset_n;
    reg rx;
    reg [7:0] data_to_send;
    reg tx_start_tick;

    // Sinais de Saída do Top
    wire tx;
    wire [7:0] data_received;
    wire rx_ready_tick;
    wire tx_busy;

    // Parâmetros de Tempo (9600 Baud @ 12MHz)
    localparam BIT_PERIOD = 104167; // ns

    // Instância do Módulo Top
    uart_top uut (
        .clk(clk),
        .reset_n(reset_n),
        .rx(rx),
        .tx(tx),
        .data_received(data_received),
        .rx_ready_tick(rx_ready_tick),
        .data_to_send(data_to_send),
        .tx_start_tick(tx_start_tick),
        .tx_busy(tx_busy)
    );

    // Gerador de Clock 12MHz
    always #41.66 clk = ~clk;

    // --- Tarefa para Simular a Chegada de um Byte (RX) ---
    task simulate_rx_input;
        input [7:0] byte;
        integer i;
        begin
            $display("[TB] Enviando para o FPGA (RX): %h", byte);
            rx = 0; #(BIT_PERIOD); // Start Bit
            for (i = 0; i < 8; i = i + 1) begin
                rx = byte[i]; #(BIT_PERIOD); // Data Bits
            end
            rx = 1; #(BIT_PERIOD); // Stop Bit
        end
    endtask

    initial begin
        // --- 1. Inicialização ---
        clk = 0;
        reset_n = 0; // Ativa Reset
        rx = 1;      // Linha RX em repouso
        data_to_send = 8'h0;
        tx_start_tick = 0;

        #200 reset_n = 1; // Libera Reset
        #1000;

        // --- 2. Testando Recepção (O FPGA recebe do PC) ---
        simulate_rx_input(8'hAB); // Envia o byte 0xAB
        
        // Espera o pulso de pronto do receptor interno
        @(posedge rx_ready_tick);
        if (data_received == 8'hAB)
            $display("[TB] SUCESSO: FPGA recebeu 0xAB corretamente.");
        else
            $display("[TB] ERRO: FPGA recebeu %h", data_received);

        #50000; // Espera um pouco

        // --- 3. Testando Transmissão (O FPGA envia para o PC) ---
        $display("[TB] Solicitando ao FPGA enviar (TX): 0x55");
        data_to_send = 8'h55;
        @(posedge clk);
        tx_start_tick = 1;
        @(posedge clk);
        tx_start_tick = 0;

        // Monitora a linha TX para ver se o dado sai corretamente
        // Aqui você veria as transições no GTKWave
        @(negedge tx_busy); // Espera o transmissor terminar
        $display("[TB] Transmissão concluída pelo FPGA.");

        #200000;
        $display("[TB] Fim da Simulação.");
        $finish;
    end

    initial begin
        $dumpfile("uart_top_tb.vcd");
        $dumpvars(0, uart_top_tb);
    end

endmodule