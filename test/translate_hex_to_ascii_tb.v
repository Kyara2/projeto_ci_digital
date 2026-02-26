`timescale 1ns / 1ps

module translate_hex_to_ascii_tb();

    // Parâmetro de teste: 2 bytes (16 bits) -> 4 caracteres ASCII (32 bits)
    parameter NUM_BYTES = 2;
    
    reg  [(NUM_BYTES*8)-1:0] data_in;
    wire [(NUM_BYTES*2*8)-1:0] ascii_out;

    // Instância da UUT
    translate_hex_to_ascii #(.NUM_BYTES(NUM_BYTES)) uut (
        .data_in(data_in),
        .ascii_out(ascii_out)
    );

    initial begin
        $display("Iniciando teste de tradução Hex -> ASCII...");
        $display("-------------------------------------------");

        // Teste 1: Valor 0x1234
        // Esperado: "1" (0x31), "2" (0x32), "3" (0x33), "4" (0x34)
        data_in = 16'h1234;
        #10;
        $display("Entrada: %h | Saída ASCII (Hex): %h", data_in, ascii_out);
        $display("Interpretado: %c%c%c%c", 
                  ascii_out[31:24], ascii_out[23:16], 
                  ascii_out[15:8],  ascii_out[7:0]);

        #20;

        // Teste 2: Valor com Letras 0xABCD
        // Esperado: "A" (0x41), "B" (0x42), "C" (0x43), "D" (0x44)
        data_in = 16'hABCD;
        #10;
        $display("Entrada: %h | Saída ASCII (Hex): %h", data_in, ascii_out);
        $display("Interpretado: %c%c%c%c", 
                  ascii_out[31:24], ascii_out[23:16], 
                  ascii_out[15:8],  ascii_out[7:0]);

        #20;

        // Teste 3: Mistura 0xF0E1
        data_in = 16'hF0E1;
        #10;
        $display("Entrada: %h | Saída ASCII (Hex): %h", data_in, ascii_out);
        $display("Interpretado: %c%c%c%c", 
                  ascii_out[31:24], ascii_out[23:16], 
                  ascii_out[15:8],  ascii_out[7:0]);

        $display("-------------------------------------------");
        $finish;
    end

    // Visualização no GTKWave
    initial begin
        $dumpfile("translate_hex_to_ascii_tb.vcd");
        $dumpvars(0, translate_hex_to_ascii_tb);
    end

endmodule