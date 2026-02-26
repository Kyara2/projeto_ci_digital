`timescale 1ns / 1ps

module button_interface_tb();

    // Sinais de entrada (reg) e saída (wire)
    reg clk;
    reg btn_in;
    wire btn_tick;

    // Instancia o módulo sob teste (UUT)
    button_interface uut (
        .clk(clk),
        .btn_in(btn_in),
        .btn_tick(btn_tick)
    );

    // Geração do Clock de 12 MHz
    // Período: 1 / 12MHz = 83.33ns. Metade do ciclo = 41.66ns
    always begin
        #41.66 clk = ~clk;
    end

    initial begin
        // Inicialização
        clk = 0;
        btn_in = 1; // Botão solto (Active Low)
        
        $display("Iniciando simulação...");
        #100;

        // --- Simulação de Aperto de Botão com Ruído (Bouncing) ---
        $display("Simulando ruído de descida (bouncing)...");
        btn_in = 0; #100;
        btn_in = 1; #150;
        btn_in = 0; #200;
        btn_in = 1; #100;
        
        // Agora o botão estabiliza em 0 (pressionado)
        $display("Botão estabilizado em LOW. Aguardando tempo de debounce...");
        btn_in = 0;

        // Precisamos esperar mais de 1.200.000 ciclos. 
        // 1.200.000 * 83.33ns = ~100ms
        // Em simulação, isso pode ser demorado. 
        // Se quiser testar rápido, diminua o 'number_of_cycles' no código original.
        #105000000; // Espera 105ms

        if (btn_tick) 
            $display("Sucesso: btn_tick detectado após debounce!");
        else 
            $display("Erro: btn_tick não detectado.");

        #1000;

        // --- Simulação de Soltura de Botão ---
        $display("Simulando soltura do botão...");
        btn_in = 1; 
        
        #105000000; // Espera mais 105ms para estabilizar em HIGH

        $display("Simulação finalizada.");
        $finish;
    end

    // Opcional: Gerar arquivo para visualizar as ondas no GTKWave
    initial begin
        $dumpfile("button_interface_tb.vcd");
        $dumpvars(0, button_interface_tb);
    end

endmodule