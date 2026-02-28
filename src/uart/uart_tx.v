`timescale 1ns / 1ps

module uart_tx 
(
    input wire clk,
    input wire reset,
    input wire [7:0] data_in,
    input wire tx_start,
    output reg tx,
    output reg tx_done
);

    // Estados da maquina
    localparam IDLE = 0, START = 1, DATA = 2, STOP = 3, DONE = 4;
	
	// Parametros para o divisor de clock
    parameter CLK_FREQ = 12_000_000; // Frequencia do clock principal (12 MHz)
    parameter BAUD_RATE = 9_600;     // Baud rate desejada de 9600
    localparam CLK_PER_BIT = CLK_FREQ / (BAUD_RATE); // Obter o divisor de frequencia adequado de  16'd1250;

    reg [2:0] state, next_state;
    reg [7:0] shift_reg;
    reg [2:0] bit_counter;
    reg [15:0] clk_counter; // max baud rate of 65535
	reg load_data;
	reg enable_counter;
	reg enable_shift;
	reg tx_reg;
	 
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
			tx_reg <= 0;
        end else if (enable_shift) begin
			tx_reg <= shift_reg[bit_counter];
		end else if (load_data) begin
		    shift_reg <= data_in;
            tx_reg <= 0;
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
                if (tx_start && !tx_done) begin
                   next_state <= START;
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
                    next_state <= DONE;
				end
            end

            DONE: begin
                next_state <= IDLE;
            end

            default: begin
                // Estado de seguranca
                next_state <= IDLE;
            end

        endcase
    end
	
	// Logica combinacional para determinar a saida e sinais de controle interno
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            // Reset de todos os sinais
            tx_done <= 0;
			tx <= 1;
            bit_counter <= 3'b0;
            enable_counter <= 0;
			enable_shift <= 0;
			load_data <= 0;
        end else begin
            case (state)
                IDLE: begin
                    tx_done <= 0; // Garante que tx_done e limpo
					tx <= 1;
                    bit_counter <= 3'b0;
                    enable_counter <= 0;
					enable_shift <= 0;
					load_data <= 0;
                end

                START: begin
					tx <= 0;
 					tx_done <= 0;
					bit_counter <= 3'b0;
					enable_counter <= 1;
					enable_shift <= 0;
					load_data <= 1;
                end

                DATA: begin
					tx <= tx_reg;
 					tx_done <= 0;
					enable_counter <= 1;
					enable_shift <= 1;
					load_data <= 0;
					if (clk_counter == CLK_PER_BIT - 1) begin
                        bit_counter <= bit_counter + 1'b1;
					end
				end

                STOP: begin
					tx <= 1;
                    tx_done <= 0; 
                    bit_counter <= 3'b0;
                    enable_counter <= 1;
					enable_shift <= 0;
					load_data <= 0;
                end

                DONE: begin
					tx <= 1;
                    tx_done <= 1; // Sinaliza que a transmissao foi concluida
                    bit_counter <= 3'b0;
                    enable_counter <= 0;
					enable_shift <= 0;
					load_data <= 0;
                end

                default: begin
					tx <= 1;
                    tx_done <= 0; // Garante que tx_done e limpo
                    bit_counter <= 3'b0;
                    enable_counter <= 0;
					enable_shift <= 0;
					load_data <= 0;
                end
					 
            endcase
        end
    end

endmodule