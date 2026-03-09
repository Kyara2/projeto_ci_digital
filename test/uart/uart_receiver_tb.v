`timescale 1ns/1ps

module uart_receiver_tb;

reg clk;
reg clk_enable;
reg reset;
reg rx;

wire [7:0] data_out;
wire rx_done;

integer errors = 0;


// ==========================
// Parâmetros
// ==========================

localparam CLK_PERIOD = 83;

localparam CLK_FREQ  = 12_000_000;
localparam BAUD_RATE = 9600;

localparam CLK_PER_BIT = CLK_FREQ / BAUD_RATE;
localparam UART_TIMEOUT = 20 * CLK_PER_BIT;



// ==========================
// DUT
// ==========================

uart_receiver
#(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
)
dut
(
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .data_out(data_out),
    .rx_done(rx_done)
);


// ==========================
// Clock controlado
// ==========================

initial begin
    clk = 0;
    clk_enable = 1;
end

always begin
    if (clk_enable)
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
// Envia byte UART
// ==========================

task send_uart_byte(input [7:0] byte);

integer i;

begin

    // idle
    rx = 1;
    repeat(10) @(posedge clk);

    // start bit
    rx = 0;
    repeat(CLK_PER_BIT) @(posedge clk);

    // envia dados LSB first
    for(i = 0; i < 8; i = i + 1) begin
        rx = byte[i];
        repeat(CLK_PER_BIT) @(posedge clk);
    end

    // stop bit
    rx = 1;
    repeat(CLK_PER_BIT) @(posedge clk);

end

endtask



// ==========================
// Teste
// ==========================

task run_test(input [7:0] byte);

integer timeout;

begin

    send_uart_byte(byte);

    timeout = 0;

    while(!rx_done && timeout < UART_TIMEOUT) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if(timeout == UART_TIMEOUT) begin
        $display("ERRO: timeout RX (byte=%h data_out=%h)", byte, data_out);
        errors = errors + 1;
    end
    else if(data_out == byte)
        $display("PASS: RX recebeu %h", byte);
    else begin
        $display("ERRO: esperado %h recebido %h", byte, data_out);
        errors = errors + 1;
    end

end
endtask


initial begin

    $display("==== TESTE UART RECEIVER ====");

    rx = 1;
    reset = 0;

    do_reset();

    run_test(8'h55);
    run_test(8'hA3);
    run_test(8'hF0);

    if(errors == 0)
        $display("RESULTADO FINAL: PASSOU");
    else
        $display("RESULTADO FINAL: %d ERROS", errors);

	clk_enable = 0;
	
end

endmodule