`timescale 1ns/1ps

module translate_hex_to_ascii_tb;

    //=====================================================
    // PARAMETRO
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

    reg  [(NUM_BYTES*8)-1:0] data_in;
    wire [(NUM_BYTES*2)*8-1:0] ascii_out;

    integer tests;
    integer errors;


    //=====================================================
    // DUT
    //=====================================================

    translate_hex_to_ascii #(
        .NUM_BYTES(NUM_BYTES)
    ) dut (
        .data_in(data_in),
        .ascii_out(ascii_out)
    );


    //=====================================================
    // MODELO HEX → ASCII
    //=====================================================

    function [7:0] hex_model;

        input [3:0] hex;

        begin

            if(hex <= 9)
                hex_model = "0" + hex;
            else
                hex_model = "A" + (hex - 10);

        end

    endfunction


    //=====================================================
    // TASK DE TESTE
    //=====================================================

    task run_test;

        input [(NUM_BYTES*8)-1:0] data;

        reg [(NUM_BYTES*2)*8-1:0] expected;

        integer i;

        begin

            @(posedge clk);

            data_in = data;

            for(i=0;i<NUM_BYTES*2;i=i+1)
            begin
                expected[i*8 +:8] =
                    hex_model(data[i*4 +:4]);
            end

            @(posedge clk);

            tests = tests + 1;

            if(ascii_out !== expected) begin

                $display("ERRO hex=%h esperado=%s obtido=%s",
                          data, expected, ascii_out);

                errors = errors + 1;

            end
            else begin

                $display("PASSOU hex=%h ascii=%s",
                          data, ascii_out);

            end

        end

    endtask


    //=====================================================
    // TESTES
    //=====================================================

    initial begin

        tests  = 0;
        errors = 0;

        $display("==== TESTE translate_hex_to_ascii ====");

        run_test(16'h0123);
        run_test(16'h4567);
        run_test(16'h89AB);
        run_test(16'hCDEF);

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