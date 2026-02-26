`timescale 1ns / 1ps

module uart_top_tb;

    reg clk;
    reg reset_n;
    reg rx_wire;
    wire tx_wire;

    // Sinais de interface interna
    wire [7:0] data_from_pc;
    wire rx_ready;
    reg [7:0] data_to_pc;
    reg tx_start;
    wire tx_busy;

    // Configuração para 12MHz e 9600 Baud
    localparam CLK_PERIOD = 83; 
	
	localparam CLK_PER_BIT = 16'd1250; // Assumindo 9600 baud rate e 12 MHz clock

    localparam BIT_PERIOD = 1250 * CLK_PERIOD;

    uart_top uut (
        .clk(clk),
        .reset_n(reset_n),
        .rx(rx_wire),
        .tx(tx_wire),
        .data_received(data_from_pc),
        .rx_ready_tick(rx_ready),
        .data_to_send(data_to_pc),
        .tx_start_tick(tx_start),
        .tx_busy(tx_busy)
    );

    always #(CLK_PERIOD / 2) clk = ~clk;

    initial begin
        // Inicialização
        clk = 0; reset_n = 0; rx_wire = 1; tx_start = 0; data_to_pc = 8'h00;
        
        #200 reset_n = 1;
        #500;

        // --- CENA 1: PC envia dado para o FPGA ---
        $display("[SIM] PC enviando 0x35...");
        drive_rx_pin(8'h35);
        
        // Espera o módulo interno detectar que o dado chegou
        wait(rx_ready);
        $display("[FPGA Internal] Módulo detectou dado recebido: %h", data_from_pc);

        # (BIT_PERIOD * 2);

        // --- CENA 2: Módulo interno envia dado para o PC ---
        $display("[FPGA Internal] Solicitando envio de 0xBC para o PC...");
        @(posedge clk);
        data_to_pc = 8'hBC;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;

        // Aguarda a linha TX começar a oscilar
        wait(tx_wire == 0);
        $display("[SIM] Linha TX começou a transmitir dados do FPGA...");

        #(BIT_PERIOD * 11);
        $display("--- Simulação Finalizada ---");
        $stop;
    end

    // Tarefa para simular o bit-banging do PC
    task drive_rx_pin(input [7:0] byte);
        integer i;
        begin
            rx_wire = 0; #(BIT_PERIOD); // Start
            for (i = 0; i < 8; i = i + 1) begin
                rx_wire = byte[i]; #(BIT_PERIOD);
            end
            rx_wire = 1; #(BIT_PERIOD); // Stop
        end
    endtask

endmodule