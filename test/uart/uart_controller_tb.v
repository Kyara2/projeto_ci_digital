`timescale 1ns/1ps

module uart_controller_tb;

reg clk;
reg reset_n;

reg [15:0] data_to_send;
reg start_tx;

wire [15:0] data_received;
wire rx_done_tick;
wire tx_busy_total;

wire tx;
wire rx;

assign rx = tx;

integer errors = 0;

uart_controller #(
    .BYTES(2)
) dut (
    .clk(clk),
    .reset_n(reset_n),
    .data_to_send(data_to_send),
    .start_tx(start_tx),
    .data_received(data_received),
    .rx_done_tick(rx_done_tick),
    .tx_busy_total(tx_busy_total),
    .rx(rx),
    .tx(tx)
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


task run_test(input [15:0] word);
begin

    @(posedge clk);
    data_to_send = word;
    start_tx = 1;

    @(posedge clk);
    start_tx = 0;

    wait(rx_done_tick);

    if(data_received == word)
        $display("PASS: Controller %h", word);
    else begin
        $display("ERRO: esperado %h recebido %h", word, data_received);
        errors = errors + 1;
    end

end
endtask


initial begin

    $display("==== TESTE UART CONTROLLER ====");

    clk = 0;
    reset_n = 0;
    start_tx = 0;

    do_reset();

    run_test(16'h1234);
    run_test(16'hABCD);
    run_test(16'hFFFF);

    if(errors == 0)
        $display("RESULTADO FINAL: PASSOU");
    else
        $display("RESULTADO FINAL: %d ERROS", errors);

    $finish;

end

endmodule