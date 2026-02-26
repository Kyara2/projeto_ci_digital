`timescale 1ns / 1ps

module uart_tx_tb();

    // Sinais de estímulo
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg tx_start;

    // Sinais de observação
    wire tx;
    wire tx_done;

    // Parâmetros de tempo
    parameter CLK_FREQ = 12_000_000;
    parameter BAUD_RATE = 9_600;
    localparam BIT_PERIOD = 104167; // Tempo de 1 bit em ns (1/9600)

    // Instância da UUT (Unit Under Test)
    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD_RATE(BAUD_RATE)
    ) uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .tx_start(tx_start),
        .tx(tx),
        .tx_done(tx_done)
    );

    // Geração do Clock (12 MHz)
    always #41.66 clk = ~clk;

    initial begin
        // --- 1. Inicialização ---
        clk = 0;
        reset = 1;
        data_in = 8'b0;
        tx_start = 0;
        
        #200;
        reset = 0;
        #1000;

        // --- 2. Teste: Transmitir 0xA5 (10100101) ---
        // Esperado na linha TX: 
        // Start(0) -> 1 -> 0 -> 1 -> 0 -> 0 -> 1 -> 0 -> 1 -> Stop(1)
        wait_for_idle();
        send_byte(8'hA5);
        
        // Aguarda a finalização
        @(posedge tx_done);
        #100;
        $display("Transmissão do byte 0xA5 concluída.");

        // --- 3. Teste: Transmitir 0x42 ('B') ---
        #10000; // Pequeno intervalo
        send_byte(8'h42);
        
        @(posedge tx_done);
        #1000;

        $display("Simulação finalizada.");
        $finish;
    end

    // Tarefa para facilitar o envio
    task send_byte;
        input [7:0] byte;
        begin
            data_in = byte;
            @(posedge clk);
            tx_start = 1;
            @(posedge clk);
            tx_start = 0;
            $display("Iniciando envio de: %h", byte);
        end
    endtask

    // Tarefa para esperar o estado IDLE (opcional)
    task wait_for_idle;
        begin
            while (tx_done == 0 && uut.state != 0) @(posedge clk);
        end
    endtask

    // Geração de arquivo VCD para o GTKWave
    initial begin
        $dumpfile("uart_tx_tb.vcd");
        $dumpvars(0, uart_tx_tb);
    end

endmodule
endmodule