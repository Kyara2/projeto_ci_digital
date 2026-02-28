module leds_interface 
(
    input wire clk,
	input wire reset,
    input wire signal,   
	
    output wire red,     // 0 = ACESO
    output wire green,   // 0 = ACESO
    output wire blue,    // 0 = ACESO
    output wire test_led
);
	
	localparam STATE_BITS_SIZE = 4;
    reg [STATE_BITS_SIZE-1:0] state = 4'b0111;    
    
    // LEDs começam em 1 (APAGADOS)   
    reg led_red , led_green , led_blue ;
    reg test_led_reg;

    always @(posedge clk or posedge reset) begin

		if (reset) begin
			state <= 3'd7;
			test_led_reg <= 1'b1;

		end
		else if (signal == 1'b1) begin
            
            // Avança o estado
            if (state == 4'd7) state <= 4'd0;
            else state <= state + 4'd1;
		
			// alterna led state
            test_led_reg <= ~test_led_reg;

        end
    end

    // --- MAPA DE CORES ---
    // Lembrete: 0 = LIGADO (ON), 1 = DESLIGADO (OFF)
    always @(*) begin
		case (state)
			//                    R  G  B
			3'd0: {led_red, led_green, led_blue} = 3'b000; // white
			3'd1: {led_red, led_green, led_blue} = 3'b001; // red + green = yellow
			3'd2: {led_red, led_green, led_blue} = 3'b010; // red + blue = purple
			3'd3: {led_red, led_green, led_blue} = 3'b011; // red
			3'd4: {led_red, led_green, led_blue} = 3'b100; // green + blue = teal 
			3'd5: {led_red, led_green, led_blue} = 3'b101; // green
			3'd6: {led_red, led_green, led_blue} = 3'b110; // blue
			3'd7: {led_red, led_green, led_blue} = 3'b111; // dark
			default: {led_red, led_green, led_blue} = 3'b111; // dark
		endcase
    end

    // Passa os valores (que já são 0 para ligar) direto para a saída
    assign red = led_red;
    assign green = led_green;
    assign blue = led_blue;
    assign test_led = test_led_reg;

endmodule