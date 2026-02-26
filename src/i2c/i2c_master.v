`timescale 1ns/1ps

module i2c_master(
    input wire clk, reset, start,
    input wire [6:0] slave_addr,
    input wire rw,
    input wire [7:0] data_in,
    input wire ack_master,
    input wire scl_in, sda_in,
    output reg [7:0] data_slave,
    output reg scl_out, sda_out,
    output reg scl_dir, sda_dir,
    output reg done, reg_ready
);
    parameter CLK_FREQ = 12_000_000;
    parameter SCL_FREQ = 100_000; 
    localparam SCL_DIV = CLK_FREQ / (2 * SCL_FREQ);
	
	localparam COUNTER_BITS_SIZE = 22;
	localparam STATE_BIT_SIZE = 4;
	localparam BIT_INDEX_SIZE = 3;
	localparam SHIFT_REG_SIZE = 8;
	
    reg [COUNTER_BITS_SIZE-1:0] clk_counter;
    reg [STATE_BIT_SIZE-1:0] state, next_state;
    reg [BIT_INDEX_SIZE-1:0] bit_index;
    reg [SHIFT_REG_SIZE-1:0] shift_reg;
    reg scl_last;
    reg check_ack_slave;

    localparam IDLE = 0, START = 1, ADDR_DATA = 2, CHECK_ACK = 3, 
               READ_SLAVE = 4, WRITE_ACK = 5, STOP = 6, DONE = 7;

	// clock stretching
	/*
	reg [15:0] safety_timeout;

	always @(posedge clk or posedge reset) begin
		if (reset) begin
			clk_counter <= 0;
			scl_out <= 1;
			safety_timeout <= 0;
		end else begin
			// Se o SCL está preso em 0 e o Master quer 1
			if (scl_out && !scl_in && state != IDLE) begin
				if (safety_timeout >= 16'd1_000) begin // Espera ~1ms
					clk_counter <= clk_counter + 1; // Força o avanço sem forçar o pino
				end else begin
					safety_timeout <= safety_timeout + 1;
					clk_counter <= clk_counter; // Mantém pausado
				end
			end else begin
				safety_timeout <= 0;
				if (clk_counter == SCL_DIV - 1) begin
					clk_counter <= 0;
					scl_out <= ~scl_out;
				end else clk_counter <= clk_counter + 1;
			end
		end
	end
	*/
	
	always @(posedge clk or posedge reset) begin
		if (reset) begin
			clk_counter <= 0;
			scl_out <= 1;
		end else begin
			// REMOVEMOS A CHECAGEM DE SCL_IN AQUI PARA TESTE
			if (clk_counter == SCL_DIV - 1) begin
				clk_counter <= 0;
				scl_out <= ~scl_out;
			end else begin
				clk_counter <= clk_counter + 1;
			end
		end
	end

    always @(posedge clk) scl_last <= scl_out;

    always @(posedge clk or posedge reset) begin
        if (reset) state <= IDLE;
        else state <= next_state;
    end

    always @(*) begin
        next_state = state;
        case (state)
            IDLE:       if (start) next_state = START;
            START:      if (scl_last && !scl_out) next_state = ADDR_DATA;
            ADDR_DATA:  if (scl_last && !scl_out && bit_index == 0) next_state = CHECK_ACK;
            CHECK_ACK:  if (scl_last && !scl_out) begin
                            if (rw && state == ADDR_DATA) next_state = READ_SLAVE;
                            else next_state = STOP;
                        end
            READ_SLAVE: if (scl_last && !scl_out && bit_index == 0) next_state = WRITE_ACK;
            WRITE_ACK:  if (scl_last && !scl_out) next_state = (ack_master == 0) ? READ_SLAVE : STOP;
            STOP:       if (!scl_last && scl_out) next_state = DONE;
            DONE:       next_state = IDLE;
            default:    next_state = IDLE;
        endcase
    end

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            sda_out <= 1; sda_dir <= 0; scl_dir <= 0;
            done <= 0; reg_ready <= 0;
        end else begin
            case (state)
                IDLE: begin
                    sda_dir <= 0; scl_dir <= 0;
                    done <= 0; reg_ready <= 0; bit_index <= 7;
                end
                START: begin
                    if (scl_out) begin sda_out <= 0; sda_dir <= 1; end
                    scl_dir <= 0; 
                    shift_reg <= {slave_addr, rw};
                    bit_index <= 7;
                end
                ADDR_DATA: begin
                    scl_dir <= 1; sda_dir <= 1;
                    if (!scl_out) sda_out <= shift_reg[bit_index]; // Garante estabilidade
                    if (scl_last && !scl_out) begin
                        if (bit_index > 0) bit_index <= bit_index - 1;
                    end
                end
                CHECK_ACK: begin
                    sda_dir <= 0;
                    if (!scl_last && scl_out) check_ack_slave <= (sda_in == 0);
                    if (scl_last && !scl_out) begin
                        reg_ready <= check_ack_slave;
                        shift_reg <= data_in;
                        bit_index <= 7;
                    end else reg_ready <= 0;
                end
                READ_SLAVE: begin
                    sda_dir <= 0;
                    if (!scl_last && scl_out) data_slave[bit_index] <= sda_in;
                    if (scl_last && !scl_out && bit_index > 0) bit_index <= bit_index - 1;
                end
                WRITE_ACK: begin
                    sda_dir <= 1; sda_out <= ack_master;
                    if (scl_last && !scl_out) begin reg_ready <= 1; bit_index <= 7; end
                    else reg_ready <= 0;
                end
                STOP: begin
                    if (!scl_out) begin sda_dir <= 1; sda_out <= 0; end
                    else if (scl_out) begin sda_out <= 1; sda_dir <= 1; end
                end
                DONE: begin
                    done <= 1;
                    scl_dir <= 0; sda_dir <= 0;
                end
            endcase
        end
    end
endmodule