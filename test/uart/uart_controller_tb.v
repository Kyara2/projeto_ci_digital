`timescale 1ns/1ps

module uart_controller_tb;

reg clk;
reg clk_enable;
reg reset;

reg [15:0] data_to_send;
reg start_tx;

wire [15:0] data_received;
wire rx_done_tick;
wire tx_busy_total;

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

uart_controller
#(
    .BYTES(2)
)
dut
(
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


task run_test(input [15:0] word);

integer timeout;

begin

    @(posedge clk);
    data_to_send = word;
    start_tx = 1;

    @(posedge clk);
    start_tx = 0;

    timeout = 0;

    while(!rx_done_tick && timeout < 100000) begin
        @(posedge clk);
        timeout = timeout + 1;
    end

    if(timeout == 100000) begin
        $display("ERRO: timeout controller");
        errors = errors + 1;
    end
    else if(data_received == word)
        $display("PASS: Controller %h", word);
    else begin
        $display("ERRO: esperado %h recebido %h", word, data_received);
        errors = errors + 1;
    end

end
endtask


initial begin

    $display("==== TESTE UART CONTROLLER ====");

    reset = 0;
    start_tx = 0;

    do_reset();

    run_test(16'h1234);
    run_test(16'hABCD);
    run_test(16'hFFFF);

    if(errors == 0)
        $display("RESULTADO FINAL: PASSOU");
    else
        $display("RESULTADO FINAL: %d ERROS", errors);

		clk_enable = 0;

end

endmodule