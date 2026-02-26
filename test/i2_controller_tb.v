`timescale 1ns/1ps

module i2c_controller_tb;

    // Sinais do Sistema
    reg clk;
    reg reset;
    reg start_pulse;
    
    // Barramento I2C
    wire scl, sda;
    wire sda_out, sda_dir, scl_out, scl_dir;
    wire sda_in, scl_in;

    // Saídas de Dados e Debug
    wire [15:0] sensor_data;
    wire [119:0] debug_bits;

    // Instanciação do Controlador
    i2c_controller #(
        .BYTES_FROM_DATA(2),
        .BYTES_FROM_DEBUG(15)
    ) uut (
        .clk(clk),
        .reset(reset),
        .start_pulse(start_pulse),
        .sda_in(sda_in),
        .sda_out(sda_out),
        .sda_dir(sda_dir),
        .scl_in(scl_in),
        .scl_out(scl_out),
        .scl_dir(scl_dir),
        .sensor_data(sensor_data),
        .debug_bits(debug_bits)
    );

    // Conexões Tri-state para simular o meio físico
    assign scl = (scl_dir) ? scl_out : 1'bz;
    assign sda = (sda_dir) ? sda_out : 1'bz;
    assign sda_in = sda;
    assign scl_in = scl;

    // Aceleração do tempo de espera para simulação
    // Reduzimos o wait de 2.2M para 100 ciclos para o teste ser rápido
    defparam uut.master.SCL_DIV = 10; // SCL mais rápido para simular
    initial begin
        force uut.wait_counter = 24'd2_199_950; // Começa quase no fim da espera
    end

    // --- LÓGICA DO ESCRAVO (Simulando o sensor BH1750) ---
    reg [7:0] dummy_data_high = 8'hDE; // Dado simulado: 0xDE
    reg [7:0] dummy_data_low  = 8'hAD; // Dado simulado: 0xAD
    
    // Resposta de ACK automática: sempre que o mestre solta o SDA, o escravo puxa 0
    // E quando o mestre está em modo de leitura (Step 5 e 6), enviamos bits
    assign sda = (uut.master.state == 3) ? 1'b0 : 1'bz; // ACK do Slave
    
    // Simulando envio de dados do Escravo para o Mestre (Simplificado)
    assign sda = (uut.step == 5 && !sda_dir) ? dummy_data_high[uut.master.bit_index] : 
                 (uut.step == 6 && !sda_dir) ? dummy_data_low[uut.master.bit_index]  : 1'bz;

    // Geração de Clock (12MHz)
    always #41.67 clk = ~clk;

    initial begin
        // Init
        clk = 0;
        reset = 1;
        start_pulse = 0;

        #200;
        reset = 0;
        #500;

        // Pulso de Start (Simula botão A)
        $display("--- Iniciando Ciclo de Leitura I2C ---");
        start_pulse = 1;
        #100;
        start_pulse = 0;

        // Monitoramento dos Estados
        wait(uut.step == 1); $display("Step 1: Power On enviado");
        wait(uut.step == 3); $display("Step 3: Modo H-Res enviado");
        wait(uut.step == 4); $display("Step 4: Aguardando Integração...");
        wait(uut.step == 5); $display("Step 5: Lendo Byte Alto...");
        wait(uut.step == 6); $display("Step 6: Lendo Byte Baixo...");
        wait(uut.step == 7); $display("Step 7: Finalizado!");
        
        #1000;
        $display("--- Resultado Final: 0x%h ---", sensor_data);
        
        if (sensor_data == 16'hDEAD) 
            $display("TESTE PASSOU: Dados recebidos corretamente.");
        else 
            $display("TESTE FALHOU: Recebido 0x%h", sensor_data);

        $finish;
    end

endmodule