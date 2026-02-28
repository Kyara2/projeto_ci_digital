`timescale 1ns / 1ps

module ice_sugar 
	#(
	parameter ENABLE_DEBUG = 1,
	parameter CPU_INSTRUCTION_MEMORY_DEPTH = 32,
	parameter CPU_DATA_MEMORY_DEPTH=32
	)
	(
	// input gpios  ------------
    input  wire clk,
	
	// buttons
    input  wire button_reset, 
    input  wire button_a,
	
	// receive uart
    input  wire rx,
	
	// output gpios ----------------
	// transmit uart
    output wire tx,
	
	// display with 4 digits
    output wire [6:0] seg,
    output wire [3:0] digits,
	
	// led rgb and external led
	output red, green, blue, test_button_led,
	
	// i2c interface
	inout wire i2c_scl,
	inout wire i2c_sda,
	
	// sensor ultrassonico  
    output wire trigger,      
    input  wire      echo
);

	localparam DISPLAY_NUM_BYTES = 2; // 2 bytes x 8 = (2<<3) = 16 bits
	
	localparam DEBUG_NUM_BYTES = 8; // 8<<3 = 8 * 8 = 64 bits
	// cada nible precisa ser convertido em 1 byte no formato ascii
	localparam UART_TX_NUM_BYTES = DEBUG_NUM_BYTES*2 + 2; // plus new line \r\n
	localparam UART_RX_NUM_BYTES = DEBUG_NUM_BYTES*2; // 8<<3 = 8 * 8 = 64 bits
	localparam SENSOR_NUM_BYTES = 2; //  2<<3 = 2 * 8 = 16 bits

    wire button_reset_pressed;
    wire button_a_pressed;	
	
	wire [15:0] distance_in_cm;
	wire [31:0] echo_counter_debug;
		
	wire [DISPLAY_NUM_BYTES*8-1:0] display_value; 
	wire [15:0] rx_data;
	wire        rx_ready;
	wire [15:0] tx_data;
	
	wire tx_busy_total_signal;
	
	wire [SENSOR_NUM_BYTES*8-1:0] data_from_sensor;

	wire [DEBUG_NUM_BYTES*8-1:0] debug_bits;
	
    wire [(DEBUG_NUM_BYTES*2)*8 -1:0] data_converted_to_ascii; // 4 nibbles convertidos para ASCII
	wire [(DEBUG_NUM_BYTES*8)-1:0] data_converted_to_hex; // hex received from uart(ascii) after convertion
	
	wire [(UART_TX_NUM_BYTES*8)-1:0] frame_to_uart; // 4 nibbles convertidos para ASCII
	wire [(UART_RX_NUM_BYTES*8)-1:0] frame_from_uart;
	
	// cpu wires
	wire [31:0] register_data_debug;
	wire [4:0]  register_data_debug_address;
	
	assign register_data_debug_address = 5'b0_0011;
		
    //assign debug_bits = 64'h01_23_45_67_89_AB_CD_EF; // for testing only
	assign debug_bits = echo_counter_debug[15:0]; //data_from_sensor[SENSOR_NUM_BYTES*8-1:0];
	//assign debug_bits = data_converted_to_hex;
	//assign debug_bits = data_from_sensor;

	// Monta o frame: N caracteres de debug + \r\n(new line)
	assign frame_to_uart = {data_converted_to_ascii, 16'h0A0D};
	
	//assign display_value = 16'h12_34;
	assign display_value = data_from_sensor;  
	//assign display_value = data_converted_to_hex[DISPLAY_NUM_BYTES*8-1:0]; // 16'hABCD;	// display the value received on display
	
	// Se o mestre quer enviar 0, a FPGA puxa para 0.  Se o mestre quer enviar 1, a FPGA solta (1'bz) e o resistor de 2.2k sobe a linha.
	// Garante comportamento Open-Drain puro
	wire sda_in, sda_out, sda_dir;
	wire scl_in, scl_out, scl_dir;
	
	// Garante que o pino só vá para 0 ou Z (nunca force 1)
	// Correção do Tri-state para I2C. Puxa para 0 apenas se a direção for saída (1) E o dado for 0.
	// Se o dado for 1 ou a direção for entrada (0), fica em Z.
	assign i2c_scl = (scl_dir && !scl_out) ? 1'b0 : 1'bz;
	assign i2c_sda = (sda_dir && !sda_out) ? 1'b0 : 1'bz;

	// As entradas continuam iguais
	assign scl_in = i2c_scl;
	assign sda_in = i2c_sda;
	
    // Instância para Reset (gera um pulso de reset)
    button_interface btn_reset (
        .clk(clk),
        .btn_in(button_reset),
        .btn_tick(button_reset_pressed)
    );

    // Instância para Send (gera um pulso para enviar)
    button_interface btn_a (
        .clk(clk),
        .btn_in(button_a),
        .btn_tick(button_a_pressed)
    );
	
	// leds
	leds_interface leds (
		.clk(clk),
		.reset(button_reset_pressed),
		.signal(button_a_pressed),
		.red(red),
		.green(green),
		.blue(blue),
		.test_led(test_button_led)
	);
	
	// instancia do display de 4 digitos de 7 segmentos cada
	display_four_digits display_inst (
			.clk(clk),
			.reset(button_reset_pressed),
			//.start_signal(button_a_pressed),
			.start_signal(1'b1),
			//.input_value(display_value), // Mostra os 2 bytes acumulados
			.input_value(display_value),
			.seg(seg),
			.digits(digits)
		);
	
	// instancia do controlador do sensor ultrasonico HC-SR04
	controlador_ultrassonico ultrassonico (
		.clk(clk),              // Clock de 12MHz
		.reset(button_reset_pressed), 
		.trigger(trigger),      
		.echo(echo),              
		.distance_cm(data_from_sensor),
		.echo_counter_debug(echo_counter_debug)
	);
			
	// instancia do controlador de uart
	uart_controller #(
		.BYTES(UART_TX_NUM_BYTES)
		//.UART_RX_BYTE_SIZE(UART_RX_BYTE_SIZE)
		)
		
		uart_controller_main (
        .clk(clk),
        .reset_n(!button_reset_pressed),
		.data_to_send(frame_to_uart),
        //.start_tx(button_a_pressed),
		.start_tx(1'b1),
        .data_received(frame_from_uart),
        .rx_done_tick(rx_ready),
        .tx_busy_total(tx_busy_total_signal),
        .rx(rx),
        .tx(tx)
    );
    
	
	// Instancia o seu controlador que gerencia o Master e o Sensor
	i2c_controller #(
		.BYTES_FROM_DATA(SENSOR_NUM_BYTES),
		.BYTES_FROM_DEBUG(SENSOR_NUM_BYTES)
	) user_app (
		.clk(clk),
		.reset(button_reset_pressed), 
		.start_pulse(button_a_pressed), 
		.sda_in(sda_in), .scl_in(scl_in),
		.sda_out(sda_out), .scl_out(scl_out),
		.sda_dir(sda_dir), .scl_dir(scl_dir) //,
		//.debug_bits(debug_bits),
		//.sensor_data(data_from_sensor)
	);
	
	// data from uart putty terminal in ascii converted to hexadecimal values
	translate_hex_to_ascii #(.NUM_BYTES(DEBUG_NUM_BYTES)) 
		translate_to_ascii (
		.data_in(debug_bits),
		.ascii_out(data_converted_to_ascii)
    );
	
	// convert a value in ascii to hex to being used for other modules(ex.: presented in the display)
	
	//wire [DEBUG_NUM_BYTES*8-1:0] value_in_ascii_test;
	//assign value_in_ascii_test = 32'h31_32_33_34;
	translate_ascii_to_hex #(.NUM_BYTES(DEBUG_NUM_BYTES)) translate_to_hex (
		//.ascii_in(value_in_ascii_test),
		.ascii_in(frame_from_uart),
		.data_out(data_converted_to_hex)
	);
	
	//cpu risc-v
	cpu_riscv #(
		    .ENABLE_DEBUG(ENABLE_DEBUG),
			.INSTRUCTION_MEMORY_DEPTH(CPU_INSTRUCTION_MEMORY_DEPTH),
			.DATA_MEMORY_DEPTH(CPU_DATA_MEMORY_DEPTH)
		  ) 
			
		cpu  (
		.clk(clk),
		.reset(button_reset_pressed),
		
		.register_data_debug_address(register_data_debug_address),
		.register_data_debug(register_data_debug)
	);
	
// end of the module
endmodule




