`timescale 1ns/1ps

module leds_interface_tb;

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

    // clock com enable
    always begin
        if(clk_en)
            #(CLK_PERIOD/2.0) clk = ~clk;
        else
            @(posedge clk_en);
    end


    //=====================================================
    // SINAIS DO TESTBENCH
    //=====================================================

    reg reset;
    reg signal;

    wire red;
    wire green;
    wire blue;
    wire test_led;

    integer tests;
    integer errors;


    //=====================================================
    // INSTANCIA DO DUT
    //=====================================================

    leds_interface dut (
        .clk(clk),
        .reset(reset),
        .signal(signal),
        .red(red),
        .green(green),
        .blue(blue),
        .test_led(test_led)
    );


    //=====================================================
    // MODELO DE REFERENCIA PARA O MAPA DE CORES
    //=====================================================

    function [2:0] expected_color;

        input [3:0] state;

        begin

            case(state)

                4'd0: expected_color = 3'b000;
                4'd1: expected_color = 3'b001;
                4'd2: expected_color = 3'b010;
                4'd3: expected_color = 3'b011;
                4'd4: expected_color = 3'b100;
                4'd5: expected_color = 3'b101;
                4'd6: expected_color = 3'b110;
                4'd7: expected_color = 3'b111;

                default: expected_color = 3'b111;

            endcase

        end

    endfunction


    //=====================================================
    // TASK: RESET DO SISTEMA
    //=====================================================

    task apply_reset;

        begin

            reset = 1;
            signal = 0;

            repeat(3) @(posedge clk);

            reset = 0;

            @(posedge clk);

        end

    endtask


    //=====================================================
    // TASK: GERAR PULSO DE SIGNAL
    //=====================================================

    task send_signal_pulse;

        begin

            signal = 1;

            @(posedge clk);

            signal = 0;

        end

    endtask


    //=====================================================
    // TASK: VERIFICAR COR DOS LEDS
    //=====================================================

    task check_leds;

        input [3:0] expected_state;

        reg [2:0] expected;

        begin

            expected = expected_color(expected_state);

            @(posedge clk);

            tests = tests + 1;

            if({red,green,blue} !== expected) begin

                $display("ERRO estado=%0d esperado=%b obtido=%b tempo=%0t",
                        expected_state, expected, {red,green,blue}, $time);

                errors = errors + 1;

            end
            else begin

                $display("PASSOU estado=%0d leds=%b",
                        expected_state, {red,green,blue});

            end

        end

    endtask


    //=====================================================
    // SEQUENCIA DE TESTES
    //=====================================================

    integer i;

    initial begin

        tests  = 0;
        errors = 0;

        $display("==== TESTE leds_interface ====");

        //-------------------------------------------------
        // aplica reset
        //-------------------------------------------------

        apply_reset();

        //-------------------------------------------------
        // estado inicial esperado = 7
        //-------------------------------------------------

        check_leds(7);

        //-------------------------------------------------
        // percorre todos os estados
        //-------------------------------------------------

        for(i = 0; i < 8; i = i + 1)
        begin

            send_signal_pulse();

            check_leds(i);

        end


        //-------------------------------------------------
        // resultado final
        //-------------------------------------------------

        $display("==== RESULTADO FINAL ====");
        $display("TOTAL TESTES = %0d", tests);
        $display("TOTAL ERROS  = %0d", errors);

        if(errors == 0)
            $display("RESULTADO FINAL: PASSOU");
        else
            $display("RESULTADO FINAL: FALHOU");

        //-------------------------------------------------
        // apenas desabilita o clock
        //-------------------------------------------------

        clk_en = 0;

    end

endmodule