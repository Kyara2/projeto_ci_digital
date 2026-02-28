

module seven_seg_decoder 
(
    input  [3:0] bin,
    output reg [6:0] seg
);
    // Mapeamento usando seus pinos validados: [g f e d c b a]
    always @(*) begin
        case (bin)
            4'h0: seg = 7'b0111111;
            4'h1: seg = 7'b0000110;
            4'h2: seg = 7'b1011011;
            4'h3: seg = 7'b1001111;
            4'h4: seg = 7'b1100110;
            4'h5: seg = 7'b1101101;
            4'h6: seg = 7'b1111101;
            4'h7: seg = 7'b0000111;
            4'h8: seg = 7'b1111111;
            4'h9: seg = 7'b1101111;
            4'hA: seg = 7'b1110111; // A
            4'hB: seg = 7'b1111100; // b (minúsculo para diferenciar do 8)
            4'hC: seg = 7'b0111001; // C
            4'hD: seg = 7'b1011110; // d (minúsculo para diferenciar do 0)
            4'hE: seg = 7'b1111001; // E
            4'hF: seg = 7'b1110001; // F
            default: seg = 7'b0000000;
        endcase
    end
endmodule



/*
module seven_seg_decoder (
    input  [3:0] bin,
    output reg [6:0] seg
);
    // Mapeamento ACTIVE LOW (0 liga, 1 desliga)
    // Ordem dos pinos: [g f e d c b a]
    always @(*) begin
        case (bin)
            4'h0: seg = 7'b1000000;
            4'h1: seg = 7'b1111001;
            4'h2: seg = 7'b0100100;
            4'h3: seg = 7'b0110000;
            4'h4: seg = 7'b0011001;
            4'h5: seg = 7'b0010010;
            4'h6: seg = 7'b0000010;
            4'h7: seg = 7'b1111000;
            4'h8: seg = 7'b0000000;
            4'h9: seg = 7'b0010000;
            4'hA: seg = 7'b0001000; // A
            4'hB: seg = 7'b0000011; // b
            4'hC: seg = 7'b1000110; // C
            4'hD: seg = 7'b0100001; // d
            4'hE: seg = 7'b0000110; // E
            4'hF: seg = 7'b0001110; // F
            default: seg = 7'b1111111; // Tudo desligado
        endcase
    end
endmodule
*/