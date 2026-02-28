module ascii_to_hex 
(
    input  wire [7:0] ascii_in,
    output wire [3:0] hex_out
);

    // '0'-'9': 0x30 - 0x39  -> Subtrai 0x30
    // 'A'-'F': 0x41 - 0x46  -> Subtrai 0x37
    // 'a'-'f': 0x61 - 0x66  -> Subtrai 0x57

    assign hex_out = (ascii_in >= 8'h30 && ascii_in <= 8'h39) ? (ascii_in - 8'h30) : // 0-9
                     (ascii_in >= 8'h41 && ascii_in <= 8'h46) ? (ascii_in - 8'h37) : // A-F
                     (ascii_in >= 8'h61 && ascii_in <= 8'h66) ? (ascii_in - 8'h57) : // a-f
                     4'h0;


endmodule