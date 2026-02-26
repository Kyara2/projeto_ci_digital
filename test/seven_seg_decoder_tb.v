`timescale 1ns / 1ps

module seven_seg_decoder_tb();

    // Sinais de teste
    reg  [3:0] bin_in;
    wire [6:0] seg_out;

    // Instância da Unidade Sob Teste (UUT)
    seven_seg_decoder uut (
        .bin(bin_in),
        .seg(seg_out)
    );

    // Inteiro para o loop de teste
    integer i;

    initial begin
        $display("Iniciando teste do Decodificador de 7 Segmentos...");
        $display("Bin | g f e d c b a");
        $display("-------------------");

        // Inicializa a entrada
        bin_in = 4'h0;
        #10;

        // Loop para testar todos os valores de 0 a F
        for (i = 0; i < 16; i = i + 1) begin
            bin_in = i;
            #10; // Pequeno atraso para observação nas ondas
            $display(" %h  | %b", bin_in, seg_out);
        end

        // Teste do caso default (opcional, forçando um valor fora do range se fosse > 4 bits)
        #10;
        $display("-------------------");
        $display("Teste finalizado.");
        $finish;
    end

    // Gerar arquivo para visualização no GTKWave
    initial begin
        $dumpfile("seven_seg_decoder_tb.vcd");
        $dumpvars(0, seven_seg_decoder_tb);
    end

endmodule
endmodule