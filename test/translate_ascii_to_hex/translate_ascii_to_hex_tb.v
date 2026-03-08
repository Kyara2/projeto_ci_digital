`timescale 1ns/1ps

module translate_ascii_to_hex_tb;

    //=====================================================
    // PARAMETRO DO MODULO
    //=====================================================

    parameter NUM_BYTES = 2;

    //=====================================================
    // CLOCK 12 MHz
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

    reg  [(NUM_BYTES*2)*8-1:0] ascii_in;
    wire [(NUM_BYTES*8)-1:0] data_out;

    integer tests;
    integer errors;


    //=====================================================
    // DUT
    //=====================================================

    translate_ascii_to_hex #(
        .NUM_BYTES(NUM_BYTES)
    ) dut (
        .ascii_in(ascii_in),
        .data_out(data_out)
    );


    //=====================================================
    // MODELO ASCII -> HEX
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

        input [(NUM_BYTES*2)*8-1:0] ascii;

        reg [(NUM_BYTES*8)-1:0] expected;

        integer i;

        begin

            @(posedge clk);

            ascii_in = ascii;

            for(i=0;i<NUM_BYTES*2;i=i+1)
            begin
                expected[i*4 +:4] =
                    ascii_model(ascii[i*8 +:8]);
            end

            @(posedge clk);

            tests = tests + 1;

            if(data_out !== expected) begin

                $display("ERRO ascii=%h esperado=%h obtido=%h",
                          ascii, expected, data_out);

                errors = errors + 1;

            end
            else begin

                $display("PASSOU ascii=%h data=%h",
                          ascii, data_out);

            end

        end

    endtask


    //=====================================================
    // TESTES
    //=====================================================

    initial begin

        tests  = 0;
        errors = 0;

        $display("==== TESTE translate_ascii_to_hex ====");

        run_test("0123");
        run_test("4567");
        run_test("89AB");
        run_test("CDEF");

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