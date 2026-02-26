`timescale 1ns / 1ps

module leds_interface_tb();

    // Sinais de estímulo
    reg clk;
    reg reset;
    reg signal;

    // Sinais de observação (saídas do módulo)
    wire red, green, blue, test_led;

    // Instância da UUT (Unit Under Test)
    leds_interface uut (
        .clk(clk),
        .reset(reset),
        .signal(signal),
        .red(red),
        .green(green),
        .blue(blue),
        .test_led(test_led)
    );

    // Clock de 12 MHz (aprox. 83.33ns de período)
    always #41.66 clk = ~clk;

    initial begin
        // --- 1. Inicialização ---
        clk = 0;
        reset = 0;
        signal = 0;
        
        $display("Iniciando Testbench de LEDs...");
        
        // --- 2. Aplicar Reset ---
        #100;
        reset = 1;
        #100;
        reset = 0;
        $display("Reset aplicado. Estado inicial deve ser DARK (111).");
        #50;

        // --- 3. Ciclar por todas as cores ---
        // Vamos enviar 8 pulsos para percorrer todos os estados (0 a 7)
        repeat (9) begin
            @(posedge clk);
            #10 signal = 1;  // Pulso de sinal em nível alto
            @(posedge clk);
            #10 signal = 0;  // Retorna a zero
            
            // Pequeno delay para estabilizar a lógica combinacional no simulador
            #20;
            $display("Sinal recebido! LEDs (RGB): %b %b %b | Test LED: %b", red, green, blue, test_led);
            
            #100; // Espera um pouco entre trocas de cores
        end

        // --- 4. Testar Reset no meio do caminho ---
        $display("Testando Reset durante operação...");
        @(posedge clk);
        signal = 1;
        #200;
        reset = 1;
        #100;
        reset = 0;
        signal = 0;

        $display("Simulação finalizada.");
        #500;
        $finish;
    end

    // Geração de arquivo de onda para GTKWave
    initial begin
        $dumpfile("leds_interface_tb.vcd");
        $dumpvars(0, leds_interface_tb);
    end

endmodule