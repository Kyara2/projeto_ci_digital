`timescale 1ns / 1ps

module button_interface_tb;

    // ==========================
    // Sinais
    // ==========================
    reg clk;
    reg clk_enable;
    reg btn_in;

    wire btn_tick;

    // ==========================
    // Parâmetros
    // ==========================

    localparam CLK_PERIOD = 83;

    // reduzido para simulação
    localparam DEBOUNCE_SIM = 20;

    // ==========================
    // DUT
    // ==========================

    button_interface
    #(
        .CYCLES_TO_DEBOUNCE(DEBOUNCE_SIM)
    )
    dut
    (
        .clk(clk),
        .btn_in(btn_in),
        .btn_tick(btn_tick)
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
    // Task: contar ticks
    // ==========================
	task count_ticks;

		input  integer cycles;
		output integer count;

		integer i;

		begin

			count = 0;

			for (i = 0; i < cycles; i = i + 1) begin
				@(posedge clk);

				if (btn_tick)
					count = count + 1;
			end

		end

	endtask


    // ==========================
    // Task: gerar bounce
    // ==========================

    task bounce_noise;
        input integer toggles;

        integer i;

        begin
            for (i=0; i<toggles; i=i+1) begin
                @(posedge clk);
                btn_in = ~btn_in;
            end
        end
    endtask


    // ==========================
    // Task: pressionar botão
    // ==========================

	task press_button;

		integer ticks;

		begin

			$display("====================================");
			$display("Teste: pressionamento com bounce");

			// ruído antes
			bounce_noise(6);

			@(posedge clk);
			btn_in = 0;

			// bounce
			bounce_noise(5);

			// garante estado pressionado
			btn_in = 0;

			// conta ticks enquanto sistema processa
			count_ticks(DEBOUNCE_SIM + 30, ticks);

			// solta botão
			@(posedge clk);
			btn_in = 1;
			
			bounce_noise(6);

			repeat(DEBOUNCE_SIM + 10) @(posedge clk);

			if (ticks == 1)
				$display("PASSOU -> 1 tick gerado corretamente");
			else
				$display("ERRO -> esperado 1 tick, obtido %0d", ticks);

		end

	endtask


    // ==========================
    // Teste principal
    // ==========================

    initial begin

        btn_in = 1; // botão solto

        repeat(10) @(posedge clk);

        press_button();

        $display("====================================");
        $display("SIMULACAO FINALIZADA");

        clk_enable = 0;

    end

endmodule