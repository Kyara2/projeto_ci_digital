`timescale 1ns/1ps

module hex_to_ascii_tb;

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
    // SINAIS
    //=====================================================

    reg  [3:0] hex_in;
    wire [7:0] ascii_out;

    integer tests;
    integer errors;


    //=====================================================
    // DUT
    //=====================================================

    hex_to_ascii dut (
        .hex_in(hex_in),
        .ascii_out(ascii_out)
    );


    //=====================================================
    // MODELO DE REFERENCIA
    //=====================================================

    function [7:0] ascii_model;

        input [3:0] hex;

        begin

            if(hex <= 9)
                ascii_model = "0" + hex;

            else
                ascii_model = "A" + (hex - 10);

        end

    endfunction


    //=====================================================
    // TASK DE TESTE
    //=====================================================

    task run_test;

        input [3:0] hex;

        reg [7:0] expected;

        begin

            @(posedge clk);

            hex_in = hex;

            expected = ascii_model(hex);

            @(posedge clk);

            tests = tests + 1;

            if(ascii_out !== expected) begin

                $display("ERRO hex=%h esperado=%s obtido=%s tempo=%0t",
                         hex, expected, ascii_out, $time);

                errors = errors + 1;

            end
            else begin

                $display("PASSOU hex=%h ascii=%s", hex, ascii_out);

            end

        end

    endtask


    //=====================================================
    // SEQUENCIA DE TESTES
    //=====================================================

    initial begin

        tests  = 0;
        errors = 0;

        $display("==== TESTE hex_to_ascii ====");

        run_test(4'h0);
        run_test(4'h1);
        run_test(4'h2);
        run_test(4'h3);
        run_test(4'h4);
        run_test(4'h5);
        run_test(4'h6);
        run_test(4'h7);
        run_test(4'h8);
        run_test(4'h9);

        run_test(4'hA);
        run_test(4'hB);
        run_test(4'hC);
        run_test(4'hD);
        run_test(4'hE);
        run_test(4'hF);

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