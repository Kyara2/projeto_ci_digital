`timescale 1ns/1ps

module uart_full_duplex_tb;

reg clk;
reg clk_enable;
reg reset;

reg [7:0] data_to_send;
reg tx_start_tick;

wire [7:0] data_received;
wire rx_ready_tick;
wire tx_busy;

wire tx;
wire rx;

assign rx = tx;

integer errors = 0;


// ==========================
// Parâmetros
// ==========================

localparam CLK_PERIOD = 83;


// ==========================
// DUT
// ==========================

uart_full_duplex dut (
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .tx(tx),
    .data_received(data_received),
    .rx_ready_tick(rx_ready_tick),
    .data_to_send(data_to_send),
    .tx_start_tick(tx_start_tick),
    .tx_busy(tx_busy)
);


// ==========================
// Clock
// ==========================

initial begin
    clk = 0;
    clk_enable = 1;
end

always begin
    if(clk_enable)
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


task run_test(input [7:0] byte);

integer timeout;

begin

    @(posedge clk);
    data_to_send = byte;
    tx_start_tick = 1;

    @(posedge clk);
    tx_start_tick = 0;

    timeout = 0;

    while(!rx_ready_tick && timeout < 50000) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if(timeout == 50000) begin
        $display("ERRO: timeout full duplex");
        errors = errors + 1;
    end
    else if(data_received == byte)
        $display("PASS: Loopback %h", byte);
    else begin
        $display("ERRO: esperado %h recebido %h", byte, data_received);
        errors = errors + 1;
    end

end
endtask


initial begin

    $display("==== TESTE UART FULL DUPLEX ====");

    reset = 0;
    tx_start_tick = 0;

    do_reset();

    run_test(8'h12);
    run_test(8'hA5);
    run_test(8'hFF);

    if(errors == 0)
        $display("RESULTADO FINAL: PASSOU");
    else
        $display("RESULTADO FINAL: %d ERROS", errors);

	clk_enable = 0;

end

endmodule