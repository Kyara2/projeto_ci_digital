`timescale 1ns/1ps

module uart_transmitter_tb;

reg clk;
reg clk_enable;
reg reset;
reg tx_start;
reg [7:0] data_in;

wire tx;
wire tx_done;

integer errors;


// ==========================
// Parâmetros
// ==========================

localparam CLK_PERIOD = 83;

localparam CLK_FREQ  = 12_000_000;
localparam BAUD_RATE = 9600;

localparam CLK_PER_BIT  = CLK_FREQ / BAUD_RATE;
localparam UART_TIMEOUT = 20 * CLK_PER_BIT;


// ==========================
// DUT
// ==========================

uart_transmitter
#(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
)
dut (
    .clk(clk),
    .reset(reset),
    .tx_start(tx_start),
    .data_in(data_in),
    .tx(tx),
    .tx_done(tx_done)
);


// ==========================
// Clock
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
// Captura UART
// ==========================

task capture_uart_byte;
output [7:0] byte;

integer i;
reg [7:0] temp;

begin

    temp = 8'h00;

    wait(tx == 0); // start bit

    repeat(CLK_PER_BIT/2) @(posedge clk);

    for(i = 0; i < 8; i = i + 1) begin
        repeat(CLK_PER_BIT) @(posedge clk);
        temp[i] = tx;
    end

    repeat(CLK_PER_BIT) @(posedge clk); // stop

    byte = temp;

end
endtask


// ==========================
// Teste
// ==========================

task run_test;
input [7:0] byte;

reg [7:0] received;
integer timeout;

begin

    data_in = byte;

    tx_start = 1;
    @(posedge clk);
    tx_start = 0;

    capture_uart_byte(received);

    timeout = 0;

    while(!tx_done && timeout < UART_TIMEOUT) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if(timeout == UART_TIMEOUT) begin
        $display("ERRO: timeout TX");
        errors = errors + 1;
    end
    else if(received == byte)
        $display("PASS: TX enviou %h", byte);
    else begin
        $display("ERRO: esperado %h recebido %h", byte, received);
        errors = errors + 1;
    end

end
endtask


// ==========================
// Execução
// ==========================

initial begin

    $display("==== TESTE UART TRANSMITTER ====");

    reset = 0;
    tx_start = 0;

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