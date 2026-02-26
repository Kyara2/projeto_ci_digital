`timescale 1ns / 1ps

module uart_controller_tb();

    // Parâmetros do teste
    parameter BYTES = 2;
    localparam BIT_PERIOD = 104167; // 9600 Baud

    // Sinais
    reg clk;
    reg reset_n;
    reg [ (BYTES*8)-1 : 0 ] data_to_send;
    reg start_tx;
    wire [ (BYTES*8)-1 : 0 ] data_received;
    wire rx_done_tick;
    wire tx_busy_total;
    reg rx;
    wire tx;

    // Instância do Controller
    uart_controller #(.BYTES(BYTES)) uut (
        .clk(clk),
        .reset_n(reset_n),
        .data_to_send(data_to_send),
        .start_tx(start_tx),
        .data_received(data_received),
        .rx_done_tick(rx_done_tick),
        .tx_busy_total(tx_busy_total),
        .rx(rx),
        .tx(tx)
    );

    // Clock 12MHz
    always #41.66 clk = ~clk;

    // Tarefa para enviar um byte manual via RX
    task send_rx_byte;
        input [7:0] b;
        integer i;
        begin
            rx = 0; #(BIT_PERIOD); // Start
            for (i = 0; i < 8; i = i + 1) begin
                rx = b[i]; #(BIT_PERIOD);
            end
            rx = 1; #(BIT_PERIOD); // Stop
            #(BIT_PERIOD/2); // Gap
        end
    endtask

    initial begin
        // --- 1. Reset ---
        clk = 0;
        reset_n = 0;
        rx = 1;
        start_tx = 0;
        data_to_send = 0;
        #200 reset_n = 1;
        #1000;

        // --- 2. Teste de Transmissão (FPGA -> PC) ---
        // Vamos enviar 0xABCD. O Controller deve enviar 0xAB primeiro, depois 0xCD.
        $display("[TB] Iniciando Transmissao de 16 bits: 0xABCD");
        data_to_send = 16'hABCD;
        @(posedge clk);
        start_tx = 1;
        @(posedge clk);
        start_tx = 0;

        // Espera a transmissão de todos os bytes
        wait(tx_busy_total == 0);
        $display("[TB] Transmissao finalizada.");
        #200000;

        // --- 3. Teste de Recepção (PC -> FPGA) ---
        // Vamos simular a chegada de dois bytes: 0x12 seguido de 0x34.
        // O data_received final deve ser 0x1234.
        $display("[TB] Simulando Recepcao de 2 bytes: 0x12 e 0x34");
        send_rx_byte(8'h12);
        send_rx_byte(8'h34);

        // Espera o pulso de conclusão
        @(posedge rx_done_tick);
        $display("[TB] Dados recebidos no FPGA: 0x%h", data_received);
        
        if (data_received == 16'h1234)
            $display("[TB] SUCESSO: Desserializacao correta.");
        else
            $display("[TB] ERRO: Desserializacao falhou.");

        #100000;
        $finish;
    end

    initial begin
        $dumpfile("uart_controller_tb.vcd");
        $dumpvars(0, uart_controller_tb);
    end

endmodule