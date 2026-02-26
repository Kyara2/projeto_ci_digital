`timescale 1ns / 1ps

module hex_to_ascii_tb();

    // Sinais de teste
    reg  [3:0] hex_in;
    wire [7:0] ascii_out;

    // Instância da UUT (Unit Under Test)
    hex_to_ascii uut (
        .hex_in(hex_in),
        .ascii_out(ascii_out)
    );

    integer i;

    initial begin
        $display("Iniciando teste: Hex to ASCII");
        $display("Hex | ASCII (Hex) | Char");
        $display("------------------------");

        // Varre todas as 16 possibilidades (0 a 15)
        for (i = 0; i < 16; i = i + 1) begin
            hex_in = i;
            #10; // Aguarda a lógica estabilizar
            
            // Exibe o valor de entrada, o código ASCII em hex e o caractere interpretado (%c)
            $display(" %h  |     %h      |  %c", hex_in, ascii_out, ascii_out);
        end

        #10;
        $display("------------------------");
        $display("Teste finalizado.");
        $finish;
    end

    // Gerar arquivo para visualização de ondas (opcional para módulos combinacionais)
    initial begin
        $dumpfile("hex_to_ascii_tb.vcd");
        $dumpvars(0, hex_to_ascii_tb);
    end

endmodule