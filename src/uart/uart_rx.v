`timescale 1ns / 1ps

module uart_rx (
    input wire clk,
    input wire reset,
    input wire rx,
    output reg [7:0] data_out,
    output reg rx_done
);

    // Estados da maquina
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, DONE = 4, ERROR = 5;
	

	// Parametros para o divisor de clock
    parameter CLK_FREQ = 12_000_000; // Frequencia do clock principal (12 MHz)
    parameter BAUD_RATE = 9_600;     // Baud rate desejada de 9600
    localparam CLK_PER_BIT = CLK_FREQ / (BAUD_RATE); // Obter o divisor de frequencia adequado de  16'd1250;

    reg [2:0] state, next_state;
    reg [7:0] shift_reg;
    reg [2:0] bit_counter;
    reg [15:0] clk_counter;
    reg rx_stop;
	reg enable_counter;
	reg enable_shift;
	reg load_data;
	 
	// Contagem dos ciclos de clock
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            clk_counter <= 16'b0;
        end else if (enable_counter) begin
			if (clk_counter < CLK_PER_BIT - 1) begin
				clk_counter <= clk_counter + 1'b1;
			end else begin
				clk_counter <= 16'b0;
			end
        end else clk_counter <= 16'b0;
    end
	 
    // Registrador de deslocamento
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            shift_reg <= 8'b0;
			data_out <= 8'b0;
        end else if (enable_shift) begin
            shift_reg[bit_counter] <= rx;
		end else if (load_data) begin
		    data_out <= shift_reg;
		end
    end
	 
    // Logica sequencial: Transicao de estado
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    // Logica combinacional para determinar o proximo estado
    always @(*) begin
        next_state <= state; // Valor padrao: permanece no mesmo estado
        case (state)
            IDLE: begin
                if (rx == 0) begin
                    next_state <= START; // Detecta o bit de inicio
                end
            end

            START: begin
                if (clk_counter == CLK_PER_BIT - 1) begin
                    next_state <= DATA;
                end
            end

            DATA: begin
                if ((bit_counter == 7) && (clk_counter == CLK_PER_BIT - 1)) begin
                    next_state <= STOP; // Ultimo bit de dados recebido
                end
            end

            STOP: begin
				if (clk_counter == CLK_PER_BIT - 1) begin
                    if (rx_stop == 1) begin // Verifica o bit de parada
                        next_state <= DONE;
                    end else begin
                        next_state <= ERROR; // Erro na recepcao no STOP bit
                    end
				end
            end

            DONE: begin
                next_state <= IDLE;
            end
				
			ERROR: begin
			    next_state <= IDLE;
			end

            default: begin
                // Estado de seguranca
                next_state <= IDLE;
            end

        endcase
    end

    // Logica sequencial: Amostragem dos dados
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset de todos os sinais
            rx_done <= 0;
            rx_stop <= 0;
			enable_counter <= 0;
			enable_shift <= 0;
			bit_counter <= 3'b0;
			load_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    rx_done <= 0; 
		            rx_stop <= 0;
				    enable_counter <= 0;
					enable_shift <= 0;
					bit_counter <= 3'b0;
					load_data <= 0;
                end

                START: begin
                    rx_done <= 0;
		            rx_stop <= 0;
					enable_counter <= 1;
					enable_shift <= 0;
					bit_counter <= 3'b0;
					load_data <= 0;
                end

                DATA: begin
					rx_done <= 0;
		            rx_stop <= 0;
					enable_counter <= 1;
					load_data <= 0;
					enable_shift <= (clk_counter == CLK_PER_BIT / 2);
					if (clk_counter == CLK_PER_BIT - 1) begin
                        bit_counter <= bit_counter + 1'b1;
					end
					if ((bit_counter == 7) && (clk_counter == CLK_PER_BIT - 1)) begin
                        load_data <= 1;
                    end
                end

                STOP: begin
					enable_counter <= 1;
					enable_shift <= 0;
					bit_counter <= 3'b0;
					load_data <= 0;
					if (clk_counter == CLK_PER_BIT - 1) begin
					    rx_done <= 1;
					end
					if ((clk_counter == CLK_PER_BIT / 2) && rx) begin
					    rx_stop <= 1;
					end
                end

                DONE: begin
                    rx_done <= 0;
		            rx_stop <= 0;
					enable_counter <= 0;
					enable_shift <= 0;
					bit_counter <= 3'b0;
					load_data <= 0;
                end

				ERROR: begin
                    rx_done <= 0;
		            rx_stop <= 0;
					enable_counter <= 0;
					enable_shift <= 0;
					bit_counter <= 3'b0;
					load_data <= 0;
                end
					 
				default: begin
                    rx_done <= 0; 
		            rx_stop <= 0;
					enable_counter <= 0;
					enable_shift <= 0;
					bit_counter <= 3'b0;
					load_data <= 0;
                end
					 
            endcase
        end
    end

endmodule