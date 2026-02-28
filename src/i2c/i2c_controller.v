module i2c_controller 
#(
    parameter BYTES_FROM_DATA = 2, 
    parameter BYTES_FROM_DEBUG = 15
)
(
    input clk, reset,
    input wire start_pulse, // Conecte ao button_a_pressed no ice_sugar.v
    input wire sda_in, output wire sda_out, output wire sda_dir,
    input wire scl_in, output wire scl_out, output wire scl_dir,
    output [BYTES_FROM_DATA*8-1:0] sensor_data, 
    output [BYTES_FROM_DEBUG*8-1:0] debug_bits 
);
    reg start;
    reg [7:0] data_to_send;
    wire [7:0] data_from_slave;
    wire reg_ready, done;
    
    reg [3:0] step;
    reg [15:0] result_buffer;
    reg [3:0] error_code;
    reg [23:0] wait_counter;

    // Debug robusto: [DEB][Step][Error][Flags][Pins][Wait][Result]
    assign debug_bits = {
        12'hDEB, step, error_code, 
        {start, done, reg_ready, 1'b0}, 
        {sda_dir, scl_dir, sda_in, scl_in},
        wait_counter, 
        result_buffer,
        40'h0 
    };

    assign sensor_data = result_buffer;

    // Master configurado para 100kHz (Standard Mode)
    i2c_master #(.SCL_FREQ(100_000)) master ( 
        .clk(clk), .reset(reset), .start(start),
        .slave_addr(7'h23), // Endereço BH1750 (Luz)
        .rw(step >= 5),     
        .data_in(data_to_send),
        .ack_master(step == 6 ? 1'b1 : 1'b0), 
        .data_slave(data_from_slave),
        .sda_in(sda_in), .sda_out(sda_out), .sda_dir(sda_dir),
        .scl_in(scl_in), .scl_out(scl_out), .scl_dir(scl_dir),
        .done(done), .reg_ready(reg_ready)
    );

    always @(posedge clk) begin
        if (reset) begin
            step <= 0; start <= 0; wait_counter <= 0; error_code <= 0;
            result_buffer <= 16'hAAAA; // Valor inicial para testar o display
        end else begin
            case(step)
                // 0: Espera o clique do botão para começar
                0: begin
                    start <= 0;
                    if (start_pulse) begin 
                        step <= 1;
                        result_buffer <= 16'h0000; // Limpa o display ao iniciar
                    end
                end

                // 1: Power On (0x01)
                1: begin
                    data_to_send <= 8'h01;
                    start <= 1;
                    if (reg_ready) begin start <= 0; step <= 2; end
                end

                // 2: Espera fim do Power On
                2: if (done) step <= 3;

                // 3: Continuous H-Res Mode (0x10)
                3: begin
                    data_to_send <= 8'h10;
                    start <= 1;
                    if (reg_ready) begin start <= 0; step <= 4; wait_counter <= 0; end
                end

                // 4: Espera Integração (180ms - Tempo necessário para o sensor converter luz)
                4: if (wait_counter >= 24'd2_200_000) begin step <= 5; end
                   else wait_counter <= wait_counter + 1;

                // 5: Inicia Leitura (Byte Alto)
                5: begin
                    start <= 1;
                    if (reg_ready) begin
                        result_buffer[15:8] <= data_from_slave;
                        step <= 6;
                    end
                end

                // 6: Lê Byte Baixo e termina com NACK (padrão I2C para último byte)
                6: if (reg_ready) begin
                    result_buffer[7:0] <= data_from_slave;
                    start <= 0;
                    step <= 7;
                end

                // 7: Sucesso e volta ao repouso (Passo 0)
                7: if (done) begin
                    error_code <= 4'hA;
                    step <= 0; 
                end

                default: step <= 0;
            endcase
        end
    end
endmodule