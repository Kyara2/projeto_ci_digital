`timescale 1ns / 1ps

module button_interface 
	(
    input  wire clk,
    input  wire btn_in,     // Sinal bruto do pino (Active Low)
    output reg  btn_tick    // Pulso de 1 ciclo de clock na descida
);

    // Sincronização e Debounce
    reg sync_0, sync_1;
    reg btn_stable;
    reg [21:0] counter;
	
	// para clock de 12 Mhz em 20 ms entao 12 Mhz x 100 ms = 1_200_000 cycles
	localparam number_of_cycles = 21'd1_200_000;

	// evita metaestabilidade
    always @(posedge clk) begin
        sync_0 <= btn_in;
        sync_1 <= sync_0;
    end


    always @(posedge clk) begin
        if (sync_1 == btn_stable) begin
            counter <= 0;
        end else begin
            counter <= counter + 1'b1;
            if (counter == number_of_cycles) begin
                btn_stable <= sync_1;
                counter <= 0;
            end
        end
    end

    // 2. Detector de Borda (DENTRO do módulo)
    reg btn_stable_prev;
    
    always @(posedge clk) begin
        btn_stable_prev <= btn_stable;
        // Gera o tick quando o botão estável cai de 1 para 0
        btn_tick <= (btn_stable_prev == 1'b1 && btn_stable == 1'b0);
    end

endmodule