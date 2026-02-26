`timescale 1ns / 1ps

module hex_to_ascii (
    input  wire [3:0] hex_in,
    output wire [7:0] ascii_out
);

    // Lógica combinacional para conversão
    // 0-9: 0x30 a 0x39
    // A-F: 0x41 a 0x46 (A soma 0x37 pois 10 + 0x37 = 0x41)
    assign ascii_out = (hex_in < 4'd10) ? (8'h30 + hex_in) : (8'h37 + hex_in);

endmodule