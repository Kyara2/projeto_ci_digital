`timescale 1ns/1ps

module ascii_to_hex_tb;

    //=====================================================
    // CLOCK 12 MHz (IceSugar v1.5)
    //=====================================================

    parameter CLK_PERIOD = 83.333;

    reg clk;
    reg clk_en;

    initial begin
        clk = 0;
        clk_en = 1;
    end

    always begin
        if(clk_en)
            #(CLK_PERIOD/2.0) clk = ~clk;
        else
            @(posedge clk_en);
    end


    //=====================================================
    // SINAIS DO TESTE
    //=====================================================

    reg  [7:0] ascii_in;
    wire [3:0] hex_out;

    integer tests;
    integer errors;


    //=====================================================
    // DUT
    //=====================================================

    ascii_to_hex dut (
        .ascii_in(ascii_in),
        .hex_out(hex_out)
    );


    //=====================================================
    // MODELO DE REFERENCIA
    //=====================================================

    function [3:0] ascii_model;

        input [7:0] ascii;

        begin

            if(ascii >= "0" && ascii <= "9")
                ascii_model = ascii - "0";

            else if(ascii >= "A" && ascii <= "F")
                ascii_model = ascii - "A" + 10;

            else
                ascii_model = 4'hx;

        end

    endfunction


    //=====================================================
    // TASK DE TESTE
    //=====================================================

    task run_test;

        input [7:0] ascii;

        reg [3:0] expected;

        begin

            @(posedge clk);

            ascii_in = ascii;

            expected = ascii_model(ascii);

            @(posedge clk);

            tests = tests + 1;

            if(hex_out !== expected) begin

                $display("ERRO ascii=%s esperado=%h obtido=%h tempo=%0t",
                         ascii, expected, hex_out, $time);

                errors = errors + 1;

            end
            else begin

                $display("PASSOU ascii=%s hex=%h", ascii, hex_out);

            end

        end

    endtask


    //=====================================================
    // SEQUENCIA DE TESTE
    //=====================================================

    initial begin

        tests  = 0;
        errors = 0;
        ascii_in = 0;

        $display("==== TESTE ascii_to_hex ====");

		run_test("0");
		run_test("1");
		run_test("2");
		run_test("3");
		run_test("4");
		run_test("5");
		run_test("6");
		run_test("7");
		run_test("8");
		run_test("9");

		run_test("A");
		run_test("B");
		run_test("C");
		run_test("D");
		run_test("E");
		run_test("F");

        $display("==== RESULTADO FINAL ====");
        $display("TOTAL TESTES = %0d", tests);
        $display("TOTAL ERROS  = %0d", errors);

        if(errors == 0)
            $display("RESULTADO FINAL: PASSOU");
        else
            $display("RESULTADO FINAL: FALHOU");

        clk_en = 0;

    end

endmodule