`timescale 1ns / 1ps

module data_memory 
#(
    parameter DATA_WIDTH   = 32,
    parameter DATA_MEMORY_DEPTH = 256   // precisa ser potência de 2
)
(
    // Entradas
    input  wire                     clk,
    input  wire                     memory_enable_write,
    input  wire                     memory_enable_read,
    input  wire [1:0]               memory_size,      // 00=byte, 01=half, 10=word
    input  wire                     memory_sign_ext,  // 1 = signed load
    input  wire [DATA_WIDTH-1:0]    memory_address,
    input  wire [DATA_WIDTH-1:0]    memory_data_to_write,

    // Saídas
    output reg  [DATA_WIDTH-1:0]    memory_data_read,
    output wire                     misaligned_exception
);

//
// ============================================================
// Organização da memória
// ============================================================
// Memória organizada em words (32 bits)
// Endereçamento lógico é byte-addressable
//

reg [DATA_WIDTH-1:0] memory [0:DATA_MEMORY_DEPTH-1];

wire [$clog2(DATA_MEMORY_DEPTH)-1:0] word_address;

// Converte endereço byte para endereço de word
wire [DATA_WIDTH-1:0] raw_word_address;
assign raw_word_address = memory_address >> 2;

assign word_address =
    (raw_word_address < DATA_MEMORY_DEPTH) ?
    raw_word_address[$clog2(DATA_MEMORY_DEPTH)-1:0] :
    {($clog2(DATA_MEMORY_DEPTH)){1'b0}};


//
// ============================================================
// Checagem de alinhamento (RV32I)
// ============================================================
// SW -> endereço múltiplo de 4
// SH -> endereço múltiplo de 2
// SB -> qualquer endereço
//

wire misaligned_word = (memory_size == 2'b10) && (memory_address[1:0] != 2'b00);
wire misaligned_half = (memory_size == 2'b01) && (memory_address[0]   != 1'b0);

assign misaligned_exception = misaligned_word | misaligned_half;


//
// ============================================================
// Escrita Síncrona
// ============================================================
// SB, SH, SW
//

always @(posedge clk) begin
    if (memory_enable_write && !misaligned_exception) begin

        case (memory_size)

            // ------------------------
            // SB (Store Byte)
            // ------------------------
            2'b00: begin
                case (memory_address[1:0])
                    2'b00: memory[word_address][7:0]   <= memory_data_to_write[7:0];
                    2'b01: memory[word_address][15:8]  <= memory_data_to_write[7:0];
                    2'b10: memory[word_address][23:16] <= memory_data_to_write[7:0];
                    2'b11: memory[word_address][31:24] <= memory_data_to_write[7:0];
                endcase
            end

            // ------------------------
            // SH (Store Halfword)
            // ------------------------
            2'b01: begin
                if (memory_address[1] == 1'b0)
                    memory[word_address][15:0]  <= memory_data_to_write[15:0];
                else
                    memory[word_address][31:16] <= memory_data_to_write[15:0];
            end

            // ------------------------
            // SW (Store Word)
            // ------------------------
            2'b10: begin
                memory[word_address] <= memory_data_to_write;
            end

        endcase
    end
end


//
// ============================================================
// Leitura Assíncrona
// ============================================================
// LB, LBU, LH, LHU, LW
//

reg [7:0]  read_byte;
reg [15:0] read_half;
reg [31:0] read_word;

always @(*) begin

    // Defaults (evita latch)
    read_word        = 32'b0;
    read_byte        = 8'b0;
    read_half        = 16'b0;
    memory_data_read = 32'b0;

    if (memory_enable_read && !misaligned_exception) begin

        read_word = memory[word_address];

        // Seleção de byte
        case (memory_address[1:0])
            2'b00: read_byte = memory[word_address][7:0];
            2'b01: read_byte = memory[word_address][15:8];
            2'b10: read_byte = memory[word_address][23:16];
            2'b11: read_byte = memory[word_address][31:24];
        endcase

        // Seleção de halfword
        if (memory_address[1] == 1'b0)
            read_half = memory[word_address][15:0];
        else
            read_half = memory[word_address][31:16];

        case (memory_size)

            // ------------------------
            // LB / LBU
            // ------------------------
            2'b00:
                memory_data_read = memory_sign_ext ?
                    {{24{read_byte[7]}}, read_byte} :
                    {24'b0, read_byte};

            // ------------------------
            // LH / LHU
            // ------------------------
            2'b01:
                memory_data_read = memory_sign_ext ?
                    {{16{read_half[15]}}, read_half} :
                    {16'b0, read_half};

            // ------------------------
            // LW
            // ------------------------
            2'b10:
                memory_data_read = read_word;

        endcase
    end
end

endmodule