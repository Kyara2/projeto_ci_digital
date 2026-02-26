module display_four_digits (
    input clk,
	input reset,
	input start_signal,
    input [15:0] input_value, // valor dinâmico da entrada
    output [6:0] seg,
    output reg [3:0] digits
);

    reg [15:0] refresh_counter = 0;
    always @(posedge clk) refresh_counter <= refresh_counter + 16'd1;

    wire [1:0] digit_select = refresh_counter[15:14];
    reg [3:0] current_nibble;
	
	reg [15:0] display_value = 16'b0;
	reg [15:0] blank_value = 16'b0;
	
	// estados da FSM
	localparam BLANK = 0, SHOW = 1;
	reg  current_state, next_state;
	
	// Atualiza FF
	always @(posedge clk or posedge reset) begin
		if (reset) begin 
			current_state <= BLANK;
		end 
		else begin
			current_state <= next_state;
		end
	end
	
	// next state logic
	always @(*) begin
		next_state <= current_state;
		
		case (current_state)
			BLANK: begin
				if (start_signal) next_state <= SHOW;
			end
			
			SHOW: begin
				next_state <= SHOW;
			end
			default: next_state <= SHOW;
		endcase
	end
	
	// output logic
	always @(*) begin
		case (current_state) 
			BLANK: begin
				display_value <= blank_value;
			end
			
			SHOW: begin
				display_value <= input_value;
			end
			default: display_value <= input_value;
		endcase
	end
	

    always @(*) begin
        case (digit_select)
            2'b00: begin digits = 4'b1110; current_nibble = display_value[3:0];   end
            2'b01: begin digits = 4'b1101; current_nibble = display_value[7:4];   end
            2'b10: begin digits = 4'b1011; current_nibble = display_value[11:8];  end
            2'b11: begin digits = 4'b0111; current_nibble = display_value[15:12]; end
        endcase
    end

    seven_seg_decoder decoder_inst (.bin(current_nibble), .seg(seg));
endmodule