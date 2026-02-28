module translate_ascii_to_hex #(
    parameter NUM_BYTES = 2 // Quantidade de bytes brutos (ex: 2 bytes = 16 bits)
)(
    input  wire [(NUM_BYTES*2)*8-1:0] ascii_in,
    output wire [(NUM_BYTES*8)-1:0] data_out // Cada byte bruto vira 2 caracteres (16 bits)
);

    genvar i;
    generate
        for (i = 0; i < NUM_BYTES*2; i = i + 1) begin : gen_hex
            // Extrai cada nibble (4 bits) e converte individualmente
            ascii_to_hex convert (
                .ascii_in(ascii_in[i*8 +: 8]),
                .hex_out(data_out[i*4 +: 4])
            );
        end
    endgenerate

endmodule