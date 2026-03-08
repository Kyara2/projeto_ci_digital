`timescale 1ns / 1ps

module ascii_to_hex 
(
    input  wire [7:0] ascii_in,
    output wire [3:0] hex_out
);

    // Se < 0x41 (Letra 'A'), trata como número. Caso contrário, como letra.
    // Subtrai 8'h30 (48) para números '0'-'9'
    // Subtrai 8'h37 (55) para letras 'A'-'F'
    assign hex_out = (ascii_in < 8'h41) ? (ascii_in - 8'h30) : (ascii_in - 8'h37);

endmodule