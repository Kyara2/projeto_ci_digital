`timescale 1ns/1ps

module uart_top_tb;

reg clk;
reg reset_n;

reg [7:0] data_to_send;
reg tx_start_tick;

wire [7:0] data_received;
wire rx_ready_tick;
wire tx_busy;

wire tx;
wire rx;

assign rx = tx; // loopback

integer errors = 0;

uart_top dut (
    .clk(clk),
    .reset_n(reset_n),
    .rx(rx),
    .tx(tx),
    .data_received(data_received),
    .rx_ready_tick(rx_ready_tick),
    .data_to_send(data_to_send),
    .tx_start_tick(tx_start_tick),
    .tx_busy(tx_busy)
);


// clock
always #41 clk = ~clk;


// reset
task do_reset;
begin
    reset_n = 0;
    repeat(5) @(posedge clk);
    reset_n = 1;
end
endtask


task run_test(input [7:0] byte);
begin

    @(posedge clk);
    data_to_send = byte;
    tx_start_tick = 1;

    @(posedge clk);
    tx_start_tick = 0;

    wait(rx_ready_tick);

    if(data_received == byte)
        $display("PASS: Loopback %h", byte);
    else begin
        $display("ERRO: esperado %h recebido %h", byte, data_received);
        errors = errors + 1;
    end

end
endtask


initial begin

    $display("==== TESTE UART TOP ====");

    clk = 0;
    reset_n = 0;
    tx_start_tick = 0;

    do_reset();

    run_test(8'h12);
    run_test(8'hA5);
    run_test(8'hFF);

    if(errors == 0)
        $display("RESULTADO FINAL: PASSOU");
    else
        $display("RESULTADO FINAL: %d ERROS", errors);

    $finish;

end

endmodule