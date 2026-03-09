`timescale 1ns / 1ps

module reset_synchronizer_tb;

    // ==========================
    // Sinais
    // ==========================

    reg clk;
    reg clk_enable;

    reg button_reset_pressed;

    wire reset;

    // ==========================
    // Parâmetros
    // ==========================

    // Clock 12 MHz  (≈83 ns)
    localparam CLK_PERIOD = 83;

    // ==========================
    // DUT
    // ==========================

    reset_synchronizer dut
    (
        .clk(clk),
        .button_reset_pressed(button_reset_pressed),
        .reset(reset)
    );

    // ==========================
    // Clock controlado
    // ==========================

    initial begin
        clk = 0;
        clk_enable = 1;
    end

    always begin
        if (clk_enable)
            #(CLK_PERIOD/2) clk = ~clk;
        else
            @(posedge clk_enable);
    end


    // ==========================
    // Task: esperar ciclos
    // ==========================

    task wait_cycles;

        input integer cycles;
        integer i;

        begin
            for (i = 0; i < cycles; i = i + 1)
                @(posedge clk);
        end

    endtask


    // ==========================
    // Task: pressionar reset
    // ==========================

    task press_reset;

        input integer cycles;

        begin

            @(posedge clk);
            button_reset_pressed = 1;

            wait_cycles(cycles);

            @(posedge clk);
            button_reset_pressed = 0;

        end

    endtask


    // ==========================
    // TESTE 1
    // Assert imediato
    // ==========================

    task test_assert_immediate;

        begin

            $display("====================================");
            $display("TESTE 1: Assert imediato");

            button_reset_pressed = 1;

            #1;

            if (reset == 1)
                $display("PASSOU -> reset ativado imediatamente");
            else
                $display("ERRO -> reset nao ativou imediatamente");

            button_reset_pressed = 0;

            wait_cycles(5);

        end

    endtask


    // ==========================
    // TESTE 2
    // Liberação sincronizada
    // ==========================

	task test_sync_release;

		begin

			$display("====================================");
			$display("TESTE 2: Liberacao sincronizada");

			press_reset(3);

			// esperar botão soltar
			wait(button_reset_pressed == 0);

			// esperar clocks suficientes
			wait_cycles(3);

			if (reset == 0)
				$display("PASSOU -> reset liberado corretamente");
			else
				$display("ERRO -> reset ainda ativo");

		end

	endtask


    // ==========================
    // TESTE 3
    // Reset curto
    // ==========================

    task test_short_reset;

        begin

            $display("====================================");
            $display("TESTE 3: Reset curto");

            press_reset(1);

            if (reset != 1)
                $display("ERRO -> reset nao ativou");

            wait_cycles(3);

            if (reset == 0)
                $display("PASSOU -> reset liberado corretamente");
            else
                $display("ERRO -> reset permaneceu ativo");

        end

    endtask


    // ==========================
    // TESTE 4
    // Múltiplos resets
    // ==========================

    task test_multiple_resets;

        begin

            $display("====================================");
            $display("TESTE 4: Multiplos resets");

            press_reset(2);

            wait_cycles(5);

            press_reset(3);

            wait_cycles(5);

            if (reset == 0)
                $display("PASSOU -> multiplos resets funcionaram");
            else
                $display("ERRO -> reset travou");

        end

    endtask


    // ==========================
    // Monitor (debug opcional)
    // ==========================

    initial begin

        $monitor("t=%0t clk=%b btn=%b reset=%b sync_reg=%b",
            $time, clk, button_reset_pressed, reset, dut.sync_reg);

    end


    // ==========================
    // Teste principal
    // ==========================

    initial begin

        $dumpfile("reset_synchronizer_tb.vcd");
        $dumpvars(0, reset_synchronizer_tb);

        button_reset_pressed = 0;

        wait_cycles(10);

        test_assert_immediate();

        test_sync_release();

        test_short_reset();

        test_multiple_resets();

        $display("====================================");
        $display("SIMULACAO FINALIZADA");

        clk_enable = 0;

    end

endmodule