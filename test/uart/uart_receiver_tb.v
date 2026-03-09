`timescale 1ns/1ps

module uart_rx_tb;

reg clk;
reg reset;
reg rx;

wire [7:0] data_out;
wire rx_done;

integer errors = 0;

uart_rx dut (
    .clk(clk),
    .reset(reset),
    .rx(rx),
    .data_out(data_out),
    .rx_done(rx_done)
);


// clock 12MHz
always #41 clk = ~clk;


// reset
task do_reset;
begin
    reset = 1;
    repeat(5) @(posedge clk);
    reset = 0;
end
endtask


// Envia byte pela linha RX
task send_uart_byte(input [7:0] byte);
integer i;
begin

    rx = 1;
    repeat(10) @(posedge clk);

    // start bit
    rx = 0;
    repeat(1250) @(posedge clk);

    // dados
    for(i=0;i<8;i=i+1) begin
        rx = byte[i];
        repeat(1250) @(posedge clk);
    end

    // stop bit
    rx = 1;
    repeat(1250) @(posedge clk);

end
endtask


task run_test(input [7:0] byte);
begin

    send_uart_byte(byte);

    wait(rx_done);

    if(data_out == byte)
        $display("PASS: RX recebeu %h", byte);
    else begin
        $display("ERRO: RX esperado %h recebido %h", byte, data_out);
        errors = errors + 1;
    end

end
endtask


initial begin

    $display("==== TESTE UART RX ====");

    clk = 0;
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

    $finish;

end

endmodule