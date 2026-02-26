`timescale 1ns / 1ps

module uart_rx_tb();

    // Sinais do Testbench
    reg clk;
    reg reset;
    reg rx;
    wire [7:0] data_out;
    wire rx_done;

    // Parâmetros para facilitar o cálculo do tempo
    parameter CLK_FREQ = 12_000_000;
    parameter BAUD_RATE = 9_600;
    // Tempo de 1 bit em nanosegundos: (1/9600) * 10^9
    localparam BIT_PERIOD = 104167; 

    // Instância da UUT
    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    // Gerador de Clock (12 MHz)
    always #41.66 clk = ~clk;

    // Tarefa para enviar um byte via RX
    task send_byte;
        input [7:0] data;
        integer i;
        begin
            $display("Enviando byte: %h (binario: %b)", data, data);
            
            // Start Bit (Lógica 0)
            rx = 0;
            #(BIT_PERIOD);
            
            // Data Bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = data[i];
                #(BIT_PERIOD);
            end
            
            // Stop Bit (Lógica 1)
            rx = 1;
            #(BIT_PERIOD);
            
            $display("Envio do byte finalizado.");
        end
    endtask

    initial begin
        // --- 1. Inicialização ---
        clk = 0;
        reset = 1;
        rx = 1; // Linha UART em repouso é nível alto
        
        #200;
        reset = 0;
        #1000;

        // --- 2. Teste: Enviar caractere 'A' (8'h41) ---
        send_byte(8'h41); 
        
        // Espera o sinal de done
        @(posedge rx_done);
        $display("Sucesso! Dado recebido: %h", data_out);
        
        #10000; // Intervalo entre bytes

        // --- 3. Teste: Enviar caractere 'Z' (8'h5A) ---
        send_byte(8'h5A);
        
        @(posedge rx_done);
        $display("Sucesso! Dado recebido: %h", data_out);

        // --- 4. Teste de Erro (Stop Bit Falso) ---
        $display("Testando erro de Stop Bit...");
        rx = 0; #(BIT_PERIOD); // Start
        repeat(8) begin rx = 0; #(BIT_PERIOD); end // Data zeros
        rx = 0; #(BIT_PERIOD); // Erro: Stop Bit deveria ser 1, mas enviaremos 0
        
        #200000;
        $display("Fim da simulacao.");
        $finish;
    end

    // Geração de VCD para GTKWave
    initial begin
        $dumpfile("uart_rx_tb.vcd");
        $dumpvars(0, uart_rx_tb);
    end

endmodule