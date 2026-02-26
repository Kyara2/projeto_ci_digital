`timescale 1ns / 1ps

module tb_uart_tx;

    // --- Sinais ---
    reg clk;
    reg reset;
    reg [7:0] data_in;
    reg tx_start;
    wire tx;
    wire tx_done;

    // --- Variáveis Internas do Testbench ---
    reg [7:0] captured_byte;
    integer i;

    // --- Instanciação do UUT ---
    uart_tx uut (
        .clk(clk),
        .reset(reset),
        .data_in(data_in),
        .tx_start(tx_start),
        .tx(tx),
        .tx_done(tx_done)
    );


	// --- Simulation Parameters ---
    // Período do clock de 12MHz: 1 / 12MHz ≈ 83.33ns
	localparam CLK_PERIOD = 83; 

	// Assumindo 9600 baud rate e 12 MHz clock
	// Em ciclos de clock de 12MHz: 12.000.000 / 9600 = 1250 ciclos.
	localparam CLK_PER_BIT = 16'd1250;


	// Para 9600 baud, o período do bit é 1 / 9600 = 104.166,67 ns ~ 104
	// Período de 1 bit: 1250 ciclos * 83ns ≈ 103,750ns (próximo dos 104 us do 9600 baud)
    localparam BIT_PERIOD = CLK_PERIOD * CLK_PER_BIT;
	
	
	 //always #41.667 clk = ~clk; 
	// --- Geração de Clock (12 MHz para iCESugar) ---
    // 1 / 12 MHz = 83.333 ns. Usamos 41.667 para cada semi-período.
    always #(CLK_PERIOD / 2) clk = ~clk;

    // --- Sequência Principal de Teste ---
    initial begin
        // 1. Inicializa Sinais
        clk = 0;
        reset = 1;
        tx_start = 0;
        data_in = 8'h00;
        captured_byte = 8'h00;

        $display("---------------------------------------------------------");
        $display("Iniciando Testbench UART TX (12 MHz / 9600 Baud)...");
        $display("---------------------------------------------------------");

        // 2. Libera o Reset
        #200 reset = 0;
        #100;

        // 3. Casos de Teste
        send_byte(8'hA5); // Binário: 10100101
        #(BIT_PERIOD);   // Espera entre transferências

        send_byte(8'h3C); // Binário: 00111100_
        #(BIT_PERIOD);

        send_byte(8'hFF); // Todos em 1
        #(BIT_PERIOD);

        // 4. Finaliza Simulação
        #(BIT_PERIOD * 2);
        $display("---------------------------------------------------------");
        $display("Testbench Concluído com Sucesso!");
        $display("---------------------------------------------------------");
        $stop;
    end

    // --- Task: Enviar um Byte ---
    task send_byte(input [7:0] byte_to_send);
        begin
            @(posedge clk);
            data_in = byte_to_send;
            tx_start = 1;
            $display("[TX] Solicitando Envio: %h", byte_to_send);
            
            @(posedge clk);
            tx_start = 0;

            // Aguarda o hardware sinalizar o fim (tx_done)
            wait (tx_done);
            @(posedge clk);
            $display("[TX] Hardware sinalizou tx_done para %h", byte_to_send);
        end
    endtask

    // --- Acumulador de Bits (Lógica "Observadora") ---
    // Amostra o sinal 'tx' no centro de cada bit para validar a saída
    initial begin
        forever begin
            // 1. Espera pelo Start Bit (queda de tx de 1 para 0)
            wait (tx == 0); 
            $display("[Monitor] Start bit detectado em %t", $time);
            
            // 2. Move para o MEIO do start bit
            #(BIT_PERIOD / 2);
            
            // 3. Pula o start bit e vai para o MEIO do Bit 0
            #(BIT_PERIOD);
            
            // 4. Amostra 8 bits (LSB primeiro)
            for (i = 0; i < 8; i = i + 1) begin
                captured_byte[i] = tx; 
                #(BIT_PERIOD);
            end
            
            // 5. Amostra o Stop Bit (deve ser 1)
            if (tx == 1) begin
                $display("[Monitor] BYTE CAPTURADO: %h (Binário: %b) em %t", captured_byte, captured_byte, $time);
            end else begin
                $display("[Monitor] ERRO: Erro de Enquadramento (Stop bit não encontrado) em %t", $time);
            end
        end
    end

    // --- Monitor de Sinais no Console ---
    initial begin
        $monitor("Tempo=%0t | tx=%b | tx_done=%b | estado=%d", 
                 $time, tx, tx_done, uut.state);
    end

endmodule