`timescale 1ns / 1ps

module controlador_ultrassonico_tb;

    reg clk;
    reg clk_enable;
    reg reset;
    reg echo;

    wire trigger;
    wire [31:0] distance_cm;
    wire [31:0] echo_counter_debug;

    // ==========================
    // Parâmetros
    // ==========================

    localparam CLK_PERIOD = 83;     
    localparam CICLOS_POR_CM = 696;

    // ==========================
    // DUT
    // ==========================

    controlador_ultrassonico dut (
        .clk(clk),
        .reset(reset),
        .trigger(trigger),
		 .echo(echo),
        .distance_cm(distance_cm),
        .echo_counter_debug(echo_counter_debug)
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
    // Função ciclos
    // ==========================

    function integer ciclos_para_distancia;
        input integer distancia_cm;
        begin
            ciclos_para_distancia = distancia_cm * CICLOS_POR_CM;
        end
    endfunction


    // ==========================
    // Task simulação sensor
    // ==========================
	task simular_distancia;
		input integer distancia_cm;

		integer ciclos_echo;

		begin

			ciclos_echo = ciclos_para_distancia(distancia_cm);

			$display("====================================");
			$display("Simulando distancia: %0d cm", distancia_cm);
			$display("Ciclos echo esperados: %0d", ciclos_echo);

			// espera trigger
			@(posedge trigger);
			@(negedge trigger);

			repeat(10) @(posedge clk);

			@(posedge clk);
			echo = 1;

			repeat(ciclos_echo) @(posedge clk);

			echo = 0;

			// espera DUT capturar
			repeat(10) @(posedge clk);

			if (distance_cm == distancia_cm) begin
				$display("PASSOU -> distancia medida = %0d cm", distance_cm);
				$display("echo_counter = %0d", echo_counter_debug);
			end
			else begin
				$display("ERRO -> esperado %0d cm, medido %0d cm",
						 distancia_cm, distance_cm);
				$display("echo_counter = %0d", echo_counter_debug);
			end

			repeat(200) @(posedge clk);

		end
	endtask


    // ==========================
    // Simulação principal
    // ==========================

    initial begin
		reset = 1'b0;
		echo = 1'b0;
		
		
		//  espera alguns ciclos apenas para ficar mais visivel o trigger, echo iniciais
		repeat (10_000) @(posedge clk);

        reset = 1;
        echo  = 0;

        repeat(20) @(posedge clk);

        reset = 0;

        simular_distancia(10);
        simular_distancia(20);
        simular_distancia(30);

        $display("====================================");
        $display("SIMULACAO FINALIZADA");
	
		// espera um tempo apenas para o resultado da medicão final ficar mais visivel na waveform
		repeat (100_000) @(posedge clk);

        clk_enable = 0;

    end

endmodule