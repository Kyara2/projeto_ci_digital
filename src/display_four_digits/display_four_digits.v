module display_four_digits 
(
    input clk,
    input reset,
    input start_signal,
    input [15:0] input_value,

    output [6:0] seg,
    output reg [3:0] digits
);

    // ==========================
    // Refresh counter
    // ==========================

    reg [15:0] refresh_counter;

    always @(posedge clk or posedge reset) begin
        if (reset)
            refresh_counter <= 16'd0;
        else
            refresh_counter <= refresh_counter + 16'd1;
    end

    wire [1:0] digit_select = refresh_counter[15:14];


    // ==========================
    // FSM
    // ==========================

    localparam BLANK = 1'b0;
    localparam SHOW  = 1'b1;

    reg current_state;
    reg next_state;


    // State register
    always @(posedge clk or posedge reset) begin
        if (reset)
            current_state <= BLANK;
        else
            current_state <= next_state;
    end


    // Next state logic
    always @(*) begin

        case (current_state)

            BLANK:
                if (start_signal)
                    next_state = SHOW;
                else
                    next_state = BLANK;

            SHOW:
                next_state = SHOW;

            default:
                next_state = BLANK;

        endcase

    end


    // ==========================
    // Display value register
    // ==========================

    reg [15:0] display_value;

    always @(posedge clk or posedge reset) begin

        if (reset)
            display_value <= 16'h0000;

        else begin

            case (current_state)

                BLANK:
                    display_value <= 16'h0000;

                SHOW:
                    display_value <= input_value;

                default:
                    display_value <= 16'h0000;

            endcase

        end

    end


    // ==========================
    // Digit multiplex
    // ==========================

    reg [3:0] current_nibble;

    always @(*) begin

        case (digit_select)

            2'b00: begin
                digits = 4'b1110;
                current_nibble = display_value[3:0];
            end

            2'b01: begin
                digits = 4'b1101;
                current_nibble = display_value[7:4];
            end

            2'b10: begin
                digits = 4'b1011;
                current_nibble = display_value[11:8];
            end

            2'b11: begin
                digits = 4'b0111;
                current_nibble = display_value[15:12];
            end

        endcase

    end


    // ==========================
    // Decoder
    // ==========================

    seven_seg_decoder decoder_inst
    (
        .bin(current_nibble),
        .seg(seg)
    );

endmodule