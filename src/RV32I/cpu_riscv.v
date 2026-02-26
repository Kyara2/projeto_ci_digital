`timescale 1ns / 1ps

module cpu_riscv(
    input  wire        clock,            // Clock principal 
    input  wire        reiniciar,        // Sinal de reset 
    output wire [31:0] saida_pc,         // Monitor do PC 
    output wire [31:0] saida_instrucao,  // Monitor da Instrução 
    output wire [31:0] saida_ula,        // Monitor do resultado da ULA 
    output wire        saida_we_reg      // Monitor de escrita no banco 
);
    // Sinais internos de conexão [cite: 2]
    wire [31:0] fio_pc;
    reg  [31:0] proximo_fio_pc;
    wire [31:0] instrucao_atual;

    // Campos de decodificação [cite: 4]
    wire [6:0] opcode = instrucao_atual[6:0];
    wire [2:0] f3     = instrucao_atual[14:12];
    wire [6:0] f7     = instrucao_atual[31:25]; // [cite: 5]
    wire [4:0] rd     = instrucao_atual[11:7];
    wire [4:0] rs1    = instrucao_atual[19:15]; // [cite: 6]
    wire [4:0] rs2    = instrucao_atual[24:20];

    // Geradores de Imediatos [cite: 7, 8, 10, 11, 13]
    wire [31:0] imm_i = {{20{instrucao_atual[31]}}, instrucao_atual[31:20]};
    wire [31:0] imm_b = {{19{instrucao_atual[31]}}, instrucao_atual[31], instrucao_atual[7], instrucao_atual[30:25], instrucao_atual[11:8], 1'b0};
    wire [31:0] imm_s = {{20{instrucao_atual[31]}}, instrucao_atual[31:25], instrucao_atual[11:7]};
    wire [31:0] imm_j = {{11{instrucao_atual[31]}}, instrucao_atual[31], instrucao_atual[19:12], instrucao_atual[20], instrucao_atual[30:21], 1'b0};
    wire [31:0] imm_u = {instrucao_atual[31:12], 12'b0};

    // Sinais de dados e controle [cite: 14, 15, 16]
    wire [31:0] rd1, rd2, dado_gravacao_final;
    reg  [31:0] res_ula_reg;
    reg         we_reg_reg, mem_para_reg_reg, we_mem_reg;
    wire [31:0] dado_lido_mem;

    // Instanciações dos Módulos [cite: 18, 19, 20, 21]
    pc_reg UNIDADE_PC (.sinal_clk(clock), .sinal_rst(reiniciar), .entrada_pc(proximo_fio_pc), .saida_pc(fio_pc));
    mem_instrucao UNIDADE_INST (.barramento_endereco(fio_pc), .barramento_instrucao(instrucao_atual));
    banco_reg UNIDADE_REGS (.sinal_clk(clock), .sel_reg1(rs1), .sel_reg2(rs2), .dado_saida1(rd1), .dado_saida2(rd2), .reg_destino(rd), .dado_escrita(dado_gravacao_final), .habilitar_escrita(we_reg_reg));
    mem_dados UNIDADE_RAM (.sinal_clk(clock), .habilitar_escrita(we_mem_reg), .posicao_endereco(res_ula_reg), .dado_entrada(rd2), .dado_leitura(dado_lido_mem));

    // Lógica de Controle e ULA [cite: 22, 23, 24]
    always @(*) begin
        res_ula_reg    = 32'd0;
        we_reg_reg     = 1'b0;
        mem_para_reg_reg = 1'b0;
        proximo_fio_pc = fio_pc + 32'd4;
        we_mem_reg     = 1'b0;

        case (opcode)
            7'b0010011: begin // Tipo-I [cite: 24]
                we_reg_reg = 1'b1;
                case (f3)
                    3'b000: res_ula_reg = rd1 + imm_i; // ADDI [cite: 24]
                    3'b111: res_ula_reg = rd1 & imm_i; // ANDI [cite: 25]
                    3'b110: res_ula_reg = rd1 | imm_i; // ORI [cite: 26, 27]
                    3'b100: res_ula_reg = rd1 ^ imm_i; // XORI [cite: 28]
                    3'b010: res_ula_reg = ($signed(rd1) < $signed(imm_i)) ? 32'd1 : 32'd0; // SLTI [cite: 28, 29]
                    3'b011: res_ula_reg = (rd1 < imm_i) ? 32'd1 : 32'd0; // SLTIU [cite: 29, 30]
                endcase
            end
            7'b0110011: begin // Tipo-R [cite: 31]
                we_reg_reg = 1'b1;
                case (f3)
                    3'b000: res_ula_reg = (f7 == 7'b0000000) ? (rd1 + rd2) : (rd1 - rd2); // ADD/SUB [cite: 31, 32, 33]
                    3'b111: res_ula_reg = rd1 & rd2; // AND [cite: 34, 35]
                    3'b110: res_ula_reg = rd1 | rd2; // OR [cite: 36, 37]
                    3'b100: res_ula_reg = rd1 ^ rd2; // XOR [cite: 38, 39]
                    3'b001: res_ula_reg = rd1 << rd2[4:0]; // SLL [cite: 40, 41]
                    3'b101: res_ula_reg = (f7 == 7'b0000000) ? (rd1 >> rd2[4:0]) : ($signed(rd1) >>> rd2[4:0]); // SRL/SRA [cite: 42, 43, 44, 45]
                endcase
            end
            7'b1100011: begin // Desvios [cite: 46]
                case (f3)
                    3'b000: if (rd1 == rd2) proximo_fio_pc = fio_pc + imm_b; // BEQ [cite: 46, 47]
                    3'b001: if (rd1 != rd2) proximo_fio_pc = fio_pc + imm_b; // BNE [cite: 48]
                    3'b100: if ($signed(rd1) < $signed(rd2)) proximo_fio_pc = fio_pc + imm_b; // BLT [cite: 49]
                    3'b101: if ($signed(rd1) >= $signed(rd2)) proximo_fio_pc = fio_pc + imm_b; // BGE [cite: 50]
                    3'b110: if (rd1 < rd2) proximo_fio_pc = fio_pc + imm_b; // BLTU [cite: 51]
                    3'b111: if (rd1 >= rd2) proximo_fio_pc = fio_pc + imm_b; // BGEU [cite: 52, 53]
                endcase
            end
            7'b0000011: if (f3 == 3'b010) begin // LW [cite: 54]
                res_ula_reg = rd1 + imm_i;
                we_reg_reg = 1'b1;
                mem_para_reg_reg = 1'b1; // [cite: 55, 56]
            end
            7'b0100011: if (f3 == 3'b010) begin // SW [cite: 57]
                res_ula_reg = rd1 + imm_s;
                we_mem_reg = 1'b1; // [cite: 57, 58]
            end
            7'b1101111: begin // JAL [cite: 61]
                res_ula_reg = fio_pc + 32'd4;
                we_reg_reg = 1'b1;
                proximo_fio_pc = fio_pc + imm_j; // [cite: 61, 62]
            end
            7'b1100111: begin // JALR [cite: 63]
                res_ula_reg = fio_pc + 32'd4;
                we_reg_reg = 1'b1;
                proximo_fio_pc = (rd1 + imm_i) & ~32'd1; // [cite: 63, 64]
            end
            7'b0110111: begin // LUI [cite: 65]
                res_ula_reg = imm_u;
                we_reg_reg = 1'b1;
            end
            7'b0010111: begin // AUIPC [cite: 66]
                res_ula_reg = fio_pc + imm_u;
                we_reg_reg = 1'b1;
            end
        endcase
    end

    // Atribuições Finais [cite: 67]
    assign dado_gravacao_final = mem_para_reg_reg ? dado_lido_mem : res_ula_reg;
    assign saida_pc            = fio_pc; // [cite: 69]
    assign saida_instrucao     = instrucao_atual; // [cite: 70]
    assign saida_ula           = res_ula_reg; // [cite: 70]
    assign saida_we_reg        = we_reg_reg; // [cite: 71]

endmodule