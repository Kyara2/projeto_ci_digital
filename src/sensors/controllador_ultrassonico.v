`timescale 1ns / 1ps

module controlador_ultrassonico
(
    input  wire        clk,      // 12 MHz
    input  wire        reset,
    input  wire        echo,

    output reg         trigger,
	output [31:0] distance_cm,
    output wire [31:0] echo_counter_debug
);

    // =========================
    // Sincronização do echo
    // =========================
    reg [1:0] echo_sync = 0;
    always @(posedge clk)
        echo_sync <= {echo_sync[0], echo};

    wire echo_rise = (echo_sync == 2'b01);
    wire echo_fall = (echo_sync == 2'b10);

    // =========================
    // Parâmetros
    // =========================
    localparam TRIG_CICLOS = 120;      // 10 µs @ 12 MHz
    localparam ESPERA = 3_000_000; // 250 ms
	
    // =========================
    // Registradores
    // =========================
    reg [31:0] contador_geral = 0;
    reg [31:0] contador_echo  = 0;
    reg [31:0] valor_pulso    = 0;

    reg medindo = 0;

    always @(posedge clk or posedge reset)
    begin
        if (reset) begin
            trigger        <= 0;
            contador_geral <= 0;
            contador_echo  <= 0;
            valor_pulso    <= 0;
            medindo        <= 0;
        end
        else begin

            // ======================
            // Geração do Trigger
            // ======================
            contador_geral <= contador_geral + 1;

            if (contador_geral < TRIG_CICLOS)
                trigger <= 1;
            else
                trigger <= 0;

            if (contador_geral >= ESPERA)
                contador_geral <= 0;

            // ======================
            // Medição do Echo
            // ======================

            if (echo_rise) begin
                contador_echo <= 0;
                medindo <= 1;
            end

            if (medindo)
                contador_echo <= contador_echo + 1;

            if (echo_fall) begin
                valor_pulso <= contador_echo;
                medindo <= 0;
            end

        end
    end

    assign echo_counter_debug = valor_pulso;
	assign distance_cm = valor_pulso/696;

endmodule