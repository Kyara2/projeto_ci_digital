`timescale 1ns/1ps

module display_four_digits_tb;

localparam CLK_PERIOD = 83; // ~12 MHz

reg clk;
reg clk_enable;
reg rst;
reg start;
reg [15:0] data;

wire [3:0] digit;
wire [6:0] seg;

////////////////////////////////////////////////////////////
// DUT
////////////////////////////////////////////////////////////

display_four_digits dut (
    .clk(clk),
    .reset(rst),
    .start_signal(start),
    .input_value(data),
    .digits(digit),
    .seg(seg)
);

////////////////////////////////////////////////////////////
// CLOCK CONTROL (permite parar simulação)
////////////////////////////////////////////////////////////

always begin
    if(clk_enable)
        #(CLK_PERIOD/2) clk = ~clk;
    else
        @(posedge clk_enable);
end

////////////////////////////////////////////////////////////
// REFERÊNCIA DO DECODER (igual ao módulo real)
////////////////////////////////////////////////////////////

function [6:0] ref_decode;

input [3:0] value;

begin
    case(value)

        4'h0: ref_decode = 7'b0111111;
        4'h1: ref_decode = 7'b0000110;
        4'h2: ref_decode = 7'b1011011;
        4'h3: ref_decode = 7'b1001111;
        4'h4: ref_decode = 7'b1100110;
        4'h5: ref_decode = 7'b1101101;
        4'h6: ref_decode = 7'b1111101;
        4'h7: ref_decode = 7'b0000111;
        4'h8: ref_decode = 7'b1111111;
        4'h9: ref_decode = 7'b1101111;
        4'hA: ref_decode = 7'b1110111;
        4'hB: ref_decode = 7'b1111100;
        4'hC: ref_decode = 7'b0111001;
        4'hD: ref_decode = 7'b1011110;
        4'hE: ref_decode = 7'b1111001;
        4'hF: ref_decode = 7'b1110001;

        default: ref_decode = 7'b0000000;

    endcase
end

endfunction

////////////////////////////////////////////////////////////
// VERIFICAÇÃO DE UM DÍGITO
////////////////////////////////////////////////////////////

task check_digit;

input [3:0] expected_digit;
input [3:0] value;

reg [6:0] expected_seg;

begin

    expected_seg = ref_decode(value);

    wait(digit == expected_digit);
    @(posedge clk);

    if(seg !== expected_seg)
        $display("ERRO -> digit=%b esperado=%b obtido=%b",
                 digit, expected_seg, seg);
    else
        $display("PASSOU -> digit=%b valor=%h", digit, value);

end

endtask

////////////////////////////////////////////////////////////
// TESTA UM BLOCO DE 4 VALORES
////////////////////////////////////////////////////////////

task test_block;

input [3:0] d3;
input [3:0] d2;
input [3:0] d1;
input [3:0] d0;

begin

    data = {d3,d2,d1,d0};

    repeat(8) @(posedge clk);

    check_digit(4'b1110, d0);
    check_digit(4'b1101, d1);
    check_digit(4'b1011, d2);
    check_digit(4'b0111, d3);

end

endtask

////////////////////////////////////////////////////////////
// TESTE PRINCIPAL
////////////////////////////////////////////////////////////

initial begin

    $display("====================================");
    $display("Teste: display_four_digits");

    clk = 0;
    clk_enable = 1;
    rst = 0;
    start = 0;

    #200;

    rst = 1;
    #200;
    rst = 0;

    start = 1;
    #200;
    start = 0;

    //////////////////////////////////////////////////////////
    // TESTES 0 → F
    //////////////////////////////////////////////////////////

    test_block(4'h3,4'h2,4'h1,4'h0); // 0 1 2 3
    test_block(4'h7,4'h6,4'h5,4'h4); // 4 5 6 7
    test_block(4'hB,4'hA,4'h9,4'h8); // 8 9 A B
    test_block(4'hF,4'hE,4'hD,4'hC); // C D E F

    $display("====================================");
    $display("SIMULACAO FINALIZADA");

    clk_enable = 0;

end

endmodule
