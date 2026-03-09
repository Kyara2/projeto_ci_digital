`timescale 1ns/1ps

module uart_controller_tb;


// ==========================
// Clock / Reset
// ==========================

reg clk;
reg clk_enable;
reg reset;


// ==========================
// Interface aplicação
// ==========================

reg  [31:0] data_to_send;
reg         start_tx;

wire [31:0] data_received;
wire        rx_done_tick;
wire        tx_busy_total;


// ==========================
// UART física
// ==========================

wire tx;
wire rx;

integer errors;


// loopback físico
assign rx = tx;


// ==========================
// Parâmetros
// ==========================

localparam CLK_PERIOD = 83;

localparam CLK_FREQ  = 12_000_000;
localparam BAUD_RATE = 9600;

localparam CLK_PER_BIT  = CLK_FREQ / BAUD_RATE;
localparam UART_TIMEOUT = 30 * CLK_PER_BIT;


// ==========================
// DUT (4 bytes)
// ==========================

uart_controller
#(
    .BYTES(4),
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
)
dut (
    .clk(clk),
    .reset(reset),

    .data_to_send(data_to_send),
    .start_tx(start_tx),

    .data_received(data_received),
    .rx_done_tick(rx_done_tick),

    .tx_busy_total(tx_busy_total),

    .rx(rx),
    .tx(tx)
);


// ==========================
// Clock 12 MHz
// ==========================

initial begin
    clk = 0;
    clk_enable = 1;
    errors = 0;
end

always begin
    if(clk_enable)
        #(CLK_PERIOD/2) clk = ~clk;
    else
        @(posedge clk_enable);
end


// ==========================
// Reset
// ==========================

task do_reset;
begin
    reset = 1;
    repeat(5) @(posedge clk);
    reset = 0;
end
endtask


// ==========================
// Envia palavra (4 bytes)
// ==========================

task send_word;
input [31:0] value;

begin

    data_to_send = value;

    start_tx = 1;
    @(posedge clk);
    start_tx = 0;

end
endtask


// ==========================
// Espera recepção completa
// ==========================

task wait_rx;
integer timeout;

begin

    timeout = 0;

    while(!rx_done_tick && timeout < UART_TIMEOUT*16) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if(timeout >= UART_TIMEOUT*16) begin
        $display("ERRO: timeout recepcao");
        errors = errors + 1;
    end

end
endtask


// ==========================
// Teste 4 bytes
// ==========================

task run_test;
input [31:0] value;

begin

    send_word(value);

    wait_rx();

    if(data_received == value)
        $display("PASS: %h", value);
    else begin
        $display("ERRO: esperado %h recebido %h",
                 value, data_received);
        errors = errors + 1;
    end

end
endtask


// ==========================
// Execução
// ==========================

initial begin

    $display("==== TESTE UART CONTROLLER (4 BYTES) ====");

    start_tx = 0;
    reset = 0;
    data_to_send = 0;

    do_reset();

    run_test(32'h12345678);
    run_test(32'hAABBCCDD);
    run_test(32'h55AA55AA);
    run_test(32'hDEADBEEF);

    if(errors==0)
        $display("RESULTADO FINAL: PASSOU");
    else
        $display("RESULTADO FINAL: %d ERROS", errors);
	
	repeat (10) #(UART_TIMEOUT);
	
    clk_enable = 0;

end

endmodule