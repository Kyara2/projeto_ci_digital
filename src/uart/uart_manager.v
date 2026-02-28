module uart_controller #(
    parameter BYTES = 2
)(
    input  wire clk,
    input  wire reset_n,
    
    // Interface com a Aplicação (ice_sugar)
    input  wire [ (BYTES*8)-1 : 0 ] data_to_send,
    input  wire                     start_tx,
    output reg  [ (BYTES*8)-1 : 0 ] data_received,
    output reg                      rx_done_tick,
    output wire                     tx_busy_total,

    // Conexão física UART
    input  wire rx,
    output wire tx
);

    // Cálculo automático de bits para o contador (ex: se BYTES=4, bits=2; se BYTES=8, bits=3)
    localparam CNT_WIDTH = (BYTES > 1) ? $clog2(BYTES) : 1;

    // Sinais para a UART interna
    wire [7:0] uart_rx_data;
    wire       uart_rx_ready;
    reg  [7:0] uart_tx_data;
    reg        uart_tx_start;
    wire       uart_tx_busy;

    // --- INSTÂNCIA DA UART ---
    uart_top uart_inst (
        .clk(clk),
        .reset_n(reset_n),
        .tx(tx),
        .rx(rx),
        .data_received(uart_rx_data),
        .rx_ready_tick(uart_rx_ready),
        .data_to_send(uart_tx_data),
        .tx_start_tick(uart_tx_start),
        .tx_busy(uart_tx_busy)
    );

    // --- MÁQUINA DE ESTADOS DE TRANSMISSÃO (TX) ---
    // Precisamos enviar Byte N, depois N-1... até 0.
    reg [1:0] tx_state;
    reg [CNT_WIDTH:0] tx_byte_ptr; // Contador genérico

    localparam TX_IDLE  = 2'b00,
               TX_SEND  = 2'b01,
               TX_WAIT  = 2'b10;

    assign tx_busy_total = (tx_state != TX_IDLE);

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            tx_state <= TX_IDLE;
            uart_tx_start <= 0;
            tx_byte_ptr <= 0;
        end else begin
            case (tx_state)
                TX_IDLE: begin
                    if (start_tx) begin
                        tx_byte_ptr <= BYTES - 1; 
                        tx_state <= TX_SEND;
                    end
                end

                TX_SEND: begin
                    // Seleciona o byte correto do barramento largo (slice)
                    uart_tx_data <= data_to_send[tx_byte_ptr*8 +: 8];
                    uart_tx_start <= 1;
                    tx_state <= TX_WAIT;
                end

                TX_WAIT: begin
                    uart_tx_start <= 0;
                    // Espera a UART terminar o byte atual antes de ir para o próximo
                    if (!uart_tx_busy && !uart_tx_start) begin
                        if (tx_byte_ptr == 0)
                            tx_state <= TX_IDLE;
                        else begin
                            tx_byte_ptr <= tx_byte_ptr - 1;
                            tx_state <= TX_SEND;
                        end
                    end
                end
            endcase
        end
    end

    // --- LÓGICA DE RECEPÇÃO (RX) ---
    reg [CNT_WIDTH:0] rx_byte_ptr;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_received <= 0;
            rx_byte_ptr <= 0;
            rx_done_tick <= 0;
        end else begin
            rx_done_tick <= 0;
            if (uart_rx_ready) begin
                // Shift dos dados recebidos para compor o valor final
                data_received <= {data_received[(BYTES-1)*8-1:0], uart_rx_data};
                
                if (rx_byte_ptr == BYTES - 1) begin
                    rx_done_tick <= 1;
                    rx_byte_ptr <= 0;
                end else begin
                    rx_byte_ptr <= rx_byte_ptr + 1;
                end
            end
        end
    end

endmodule