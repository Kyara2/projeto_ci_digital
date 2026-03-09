`timescale 1ns/1ps

module uart_transmitter_tb;

reg clk;
reg clk_enable;
reg reset;

reg [7:0] data_in;
reg tx_start;

wire tx;
wire tx_done;

integer errors = 0;


// ==========================
// Parâmetros
// ==========================

localparam CLK_PERIOD = 83;

localparam CLK_FREQ = 12_000_000;
localparam BAUD_RATE = 9600;


// ==========================
// DUT
// ==========================

uart_transmitter
#(
    .CLK_FREQ(CLK_FREQ),
    .BAUD_RATE(BAUD_RATE)
)
dut
(
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .tx_start(tx_start),
    .tx(tx),
    .tx_done(tx_done)
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


task do_reset;
begin
    reset = 1;
    repeat(5) @(posedge clk);
    reset = 0;
end
endtask


task send_byte(input [7:0] byte);

integer timeout;

begin

    @(posedge clk);
    data_in = byte;
    tx_start = 1;

    @(posedge clk);
    tx_start = 0;

    timeout = 0;

    while(!tx_done && timeout < 20000) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if(timeout == 20000) begin
        $display("ERRO: timeout TX");
        errors = errors + 1;
    end
    else
        $display("PASS: TX enviou %h", byte);

end
endtask


initial begin

    $display("==== TESTE UART TRANSMITTER ====");

    reset = 0;
    tx_start = 0;
    data_in = 0;

    do_reset();

    send_byte(8'h55);
    send_byte(8'hAA);
    send_byte(8'hF0);

    if(errors == 0)
        $display("RESULTADO FINAL: PASSOU");
    else
        $display("RESULTADO FINAL: %d ERROS", errors);

	clk_enable = 0;

end

endmodule