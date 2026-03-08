`timescale 1ns / 1ps

module seven_seg_decoder_tb;

    // ==========================
    // Sinais
    // ==========================

    reg  [3:0] bin;
    wire [6:0] seg;

    // ==========================
    // DUT
    // ==========================

    seven_seg_decoder dut (
        .bin(bin),
        .seg(seg)
    );

    // ==========================
    // Função de referência
    // ==========================

    function [6:0] expected_seg;

        input [3:0] value;

        begin
            case (value)
                4'h0: expected_seg = 7'b0111111;
                4'h1: expected_seg = 7'b0000110;
                4'h2: expected_seg = 7'b1011011;
                4'h3: expected_seg = 7'b1001111;
                4'h4: expected_seg = 7'b1100110;
                4'h5: expected_seg = 7'b1101101;
                4'h6: expected_seg = 7'b1111101;
                4'h7: expected_seg = 7'b0000111;
                4'h8: expected_seg = 7'b1111111;
                4'h9: expected_seg = 7'b1101111;
                4'hA: expected_seg = 7'b1110111;
                4'hB: expected_seg = 7'b1111100;
                4'hC: expected_seg = 7'b0111001;
                4'hD: expected_seg = 7'b1011110;
                4'hE: expected_seg = 7'b1111001;
                4'hF: expected_seg = 7'b1110001;
                default: expected_seg = 7'b0000000;
            endcase
        end

    endfunction


    // ==========================
    // Teste de valor
    // ==========================

    task test_value;

        input [3:0] value;

        begin

            bin = value;
			
			// espera circuito combinacional
            #10;

            if (seg === expected_seg(value))
                $display("PASSOU -> bin=%h seg=%b", value, seg);
            else
                $display("ERRO -> bin=%h esperado=%b obtido=%b",
                         value, expected_seg(value), seg);

        end

    endtask


    // ==========================
    // Teste principal
    // ==========================

    integer i;

    initial begin

        $display("====================================");
        $display("Teste: seven_seg_decoder");

        for (i = 0; i < 16; i = i + 1)
            test_value(i[3:0]);

        $display("====================================");
        $display("SIMULACAO FINALIZADA");

    end

endmodule