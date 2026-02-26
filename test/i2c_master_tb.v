`timescale 1ns/1ps

module i2c_master_tb;

    // Sinais do Testbench
    reg clk;
    reg reset;
    reg start;
    reg [6:0] slave_addr;
    reg rw;
    reg [7:0] data_in;
    reg ack_master;
    
    // Sinais bidirecionais simulados
    wire scl, sda;
    
    // Saídas do módulo
    wire [7:0] data_slave;
    wire scl_out, sda_out;
    wire scl_dir, sda_dir;
    wire done, reg_ready;

    // Instanciação do Módulo (UUT)
    i2c_master #(
        .CLK_FREQ(12_000_000),
        .SCL_FREQ(100_000)      // 100kHz para facilitar visualização
    ) uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .slave_addr(slave_addr),
        .rw(rw),
        .data_in(data_in),
        .ack_master(ack_master),
        .scl_in(scl),
        .sda_in(sda),
        .data_slave(data_slave),
        .scl_out(scl_out),
        .sda_out(sda_out),
        .scl_dir(scl_dir),
        .sda_dir(sda_dir),
        .done(done),
        .reg_ready(reg_ready)
    );

    // Lógica de barramento Tri-state (Simula os resistores de Pull-up)
    assign scl = (scl_dir) ? scl_out : 1'bz;
    assign sda = (sda_dir) ? sda_out : 1'bz;

    // --- SIMULAÇÃO DO ESCRAVO (SLAVE EMULAÇÃO) ---
    // Responde com ACK (0) sempre que o mestre libera o barramento no 9º bit
    assign sda = (!sda_dir && !reset) ? 1'b0 : 1'bz; 
    // Nota: Para testes mais complexos, o slave enviaria dados reais em rw=1.
    // Aqui, forçamos o SDA em 0 quando o mestre lê, simulando ACK e dado 00h.

    // Geração do Clock (12MHz ≈ 83.33ns de período)
    always #41.67 clk = ~clk;

    initial begin
        // Inicialização
        clk = 0;
        reset = 1;
        start = 0;
        slave_addr = 7'h00;
        rw = 0;
        data_in = 8'h00;
        ack_master = 0;

        // Reset do sistema
        #200;
        reset = 0;
        #200;

        // --- CASO DE TESTE 1: ESCRITA ---
        $display("Iniciando Escrita: Endereço 0x50, Dado 0xAA");
        slave_addr = 7'h50; 
        data_in = 8'hAA;
        rw = 0;             // Write
        start = 1;
        #100;
        start = 0;

        // Aguarda o término da operação
        wait(done);
        #500;

        // --- CASO DE TESTE 2: LEITURA ---
        $display("Iniciando Leitura: Endereço 0x50");
        slave_addr = 7'h50;
        rw = 1;             // Read
        ack_master = 0;     // Mestre envia ACK após ler
        start = 1;
        #100;
        start = 0;

        wait(done);
        #1000;

        $display("Simulação finalizada.");
        $finish;
    end

    // Monitor de sinais no console
    initial begin
        $monitor("Tempo: %t | Estado: %d | SCL: %b | SDA: %b | Done: %b", 
                 $time, uut.state, scl, sda, done);
    end

endmodule