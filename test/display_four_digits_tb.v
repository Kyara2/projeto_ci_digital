`timescale 1ns / 1ps

module display_four_digits_tb();

    // Sinais de entrada
    reg clk;
    reg reset;
    reg start_signal;
    reg [15:0] input_value;

    // Sinais de saída
    wire [6:0] seg;
    wire [3:0] digits;

    // Instância da UUT
    display_four_digits uut (
        .clk(clk),
        .reset(reset),
        .start_signal(start_signal),
        .input_value(input_value),
        .seg(seg),
        .digits(digits)
    );

    // Clock de 12 MHz (83.33ns período)
    always #41.66 clk = ~clk;

    initial begin
        // --- 1. Inicialização ---
        clk = 0;
        reset = 1;
        start_signal = 0;
        input_value = 16'hABCD; // Hexadecimal para facilitar a conferência
        
        #100;
        reset = 0;
        $display("Reset liberado. Estado: BLANK (Deve mostrar 0000 ou vazio)");

        // --- 2. Verificar Multiplexação em BLANK ---
        // O contador precisa de 2^14 ciclos para mudar de dígito.
        // Em simulação, vamos esperar o tempo suficiente para ver a troca.
        #1000; 
        
        // --- 3. Iniciar Exibição ---
        $display("Enviando start_signal. Mostrando valor: %h", input_value);
        start_signal = 1;
        #100;
        start_signal = 0;

        // --- 4. Observar a varredura dos 4 dígitos ---
        // Como o seletor depende de refresh_counter[15:14], cada dígito
        // aparece por 16384 ciclos de clock. 
        // 16384 * 83.33ns = ~1.36ms por dígito.
        
        $display("Aguardando varredura dos dígitos (Dígito 0)...");
        wait(digits == 4'b1110); #100;
        $display("Dígito 0 ativo. Valor no barramento 'seg' para o nibble %h", uut.current_nibble);
        
        $display("Aguardando varredura (Dígito 1)...");
        wait(digits == 4'b1101); #100;
        $display("Dígito 1 ativo. Valor no barramento 'seg' para o nibble %h", uut.current_nibble);

        $display("Aguardando varredura (Dígito 2)...");
        wait(digits == 4'b1011); #100;
        
        $display("Aguardando varredura (Dígito 3)...");
        wait(digits == 4'b0111); #100;

        // --- 5. Mudar valor dinamicamente ---
        #500;
        input_value = 16'h1234;
        $display("Valor alterado para 1234. Verificando atualização...");

        #2000000; // Espera alguns ms para ver a transição nas ondas
        $finish;
    end

    initial begin
        $dumpfile("display_four_digits_tb.vcd");
        $dumpvars(0, display_four_digits_tb);
    end

endmodule