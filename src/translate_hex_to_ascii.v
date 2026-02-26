module translate_hex_to_ascii #(
    parameter NUM_BYTES = 2 // Quantidade de bytes brutos (ex: 2 bytes = 16 bits)
)(
    input  wire [(NUM_BYTES*8)-1:0] data_in,
    output wire [(NUM_BYTES*2)*8-1:0] ascii_out // Cada byte bruto vira 2 caracteres (16 bits)
);

    genvar i;
    generate
        for (i = 0; i < NUM_BYTES*2; i = i + 1) begin : gen_hex
            // Extrai cada nibble (4 bits) e converte individualmente
            hex_to_ascii convert (
                .hex_in(data_in[i*4 +: 4]),
                .ascii_out(ascii_out[i*8 +: 8])
            );
        end
    endgenerate

endmodule