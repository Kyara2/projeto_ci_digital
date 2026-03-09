`timescale 1ns/1ps

module uart_tx_tb;

reg clk;
reg reset;
reg [7:0] data_in;
reg tx_start;

wire tx;
wire tx_done;

integer errors = 0;

// DUT
uart_tx dut (
    .clk(clk),
    .reset(reset),
    .data_in(data_in),
    .tx_start(tx_start),
    .tx(tx),
    .tx_done(tx_done)
);

// Clock 12 MHz (≈83ns)
always #41 clk = ~clk;


// TASK: reset
task do_reset;
begin
    reset = 1;
    repeat(5) @(posedge clk);
    reset = 0;
end
endtask


// TASK: transmitir byte
task send_byte(input [7:0] byte);
begin
    @(posedge clk);
    data_in = byte;
    tx_start = 1;

    @(posedge clk);
    tx_start = 0;

    wait(tx_done);

    @(posedge clk);

    if(tx_done)
        $display("PASS: TX completou envio do byte %h", byte);
    else begin
        $display("ERRO: TX nao completou envio");
        errors = errors + 1;
    end
end
endtask


initial begin

    $display("==== TESTE UART TX ====");

    clk = 0;
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

    $finish;

end

endmodule