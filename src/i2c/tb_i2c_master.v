`timescale 1ns/1ps

module tb_i2c_master;

    reg clk;
    reg reset;
    reg start;
    reg [7:0] data_in;
	 wire [7:0] data_slave;
	 reg ack_master;
    tri1 scl;
    tri1 sda; // Linha tri-state
    wire done;
    reg rw;
    reg [6:0] slave_addr;
	 
    // Variaveis internas para capturar os dados recebidos e o endereco
    reg [6:0] received_addr;   // Registrador para armazenar o endereco recebido
    reg [7:0] received_data;   // Registrador para armazenar os dados recebidos
    reg [3:0] addr_bit_counter; // Contador para os bits do endereco
    reg [3:0] data_bit_counter; // Contador para os bits dos dados

    // Variavel para simular o escravo
    reg sda_slave;
	 
	 reg [7:0] dado_escravo;
	 
	 integer i;
	 integer negedge_detected;

    // Controle tri-state para a linha SDA
    assign sda = (sda_slave === 1'bz) ? 1'bz : sda_slave; 
	 
    i2c_master uut (
        .clk(clk),
        .reset(reset),
        .start(start),
        .data_in(data_in),
		  .data_slave(data_slave),
		  .ack_master(ack_master),
        .scl(scl),
        .sda(sda),
        .done(done),
		  .rw(rw),
		  .slave_addr(slave_addr)
    );

    initial begin
    // Inicializa os sinais
	 received_addr=0;   
	 received_data=0;   
    addr_bit_counter=0; 
    data_bit_counter=0; 
	 sda_slave = 1'bz;
    clk = 0;
    reset = 1;
    start = 0;
	 rw = 0;
	 i = 7;
    data_in = 8'hA5;
	 dado_escravo = 8'hBC;
	 slave_addr = 7'b1010101;

    // Libera o reset apos algumas ciclos de clock
    #10 reset = 0;
        
    // Inicia a transferencia de dados
    #20 start = 1;
        
    #100 start = 0;
        
	 // Espera a transferencia completar
	 wait(uut.state == 3);
		  
	 // Simula o escravo 
	 sda_slave = 0;
	
	 wait(uut.state == 2) sda_slave = 1'bz;
		  
	 // Espera a transferencia completar
	 wait(uut.state == 3);
		  
	 //Simula o escravo
	 sda_slave = 0;
	 wait(uut.state == 2) sda_slave = 1'bz;
	
	 wait(uut.state == 3);
	 sda_slave = 1;

	 wait(uut.state == 6) sda_slave = 1'bz;
	
	 // Finaliza a simulacao
    #1000 
	 
	 // Inicia a transferencia de dados
	 rw = 1;
    #20 start = 1;
	 
	 #100 start = 0;
               
	 // Espera a transferencia completar
	 wait(uut.state == 3);
	 
	 // Simula o escravo 
	 sda_slave = 0;
	 
	 wait(uut.state == 4);
	 
	 // Simula o escravo 
	 negedge_detected = 0; // Inicializar o sinal
	 
	 for (i = 7; i >= 0; i = i - 1) begin
        sda_slave = dado_escravo[i];
				
        // Aguardar uma das condicoes: borda de descida ou estado 2
		  wait (uut.state == 5 || negedge_detected);
		  
		  // Resetar o sinal apos deteccao
        negedge_detected = 0;

    end
	 
	 ack_master = 1;
	 
	 wait(uut.state == 4) sda_slave = 1'bz;
	 	 
	 #1000 $stop;
    end

	 // Detectar a borda de descida de SCL
    always @(negedge scl) begin
        negedge_detected = 1;
    end
	 
    // Geracao de clock
    always #5 clk = ~clk;

    // Monitoramento dos sinais
    initial begin
        $monitor("Time = %0t, reset = %b, start = %b, data_in = %h, scl = %b, sda = %b, done = %b", 
                 $time, reset, start, data_in, scl, sda, done);
    end
	 
    // Armazenamento do endereco recebido a cada borda de subida do SCL
    always @(posedge scl) begin
	     if (uut.state == 2) begin
            if (addr_bit_counter < 7) begin
                received_addr[6 - addr_bit_counter] <= sda; // Armazena o bit do endereco recebido
                addr_bit_counter <= addr_bit_counter + 1; // Incrementa o contador de bits do endereco
            end else if (addr_bit_counter == 7) begin
                // Quando todos os 7 bits do endereco forem recebidos, faz a comparacao
                $display("Endereco recebido: %h", received_addr);
                if (received_addr == slave_addr) begin
                    $display("Endereco corretamente recebido.");
                end else begin
                    $display("Erro na recepcao do endereco.");
                end
                addr_bit_counter <= 0; // Reseta o contador de bits do endereco
            end
		  end else begin
		      received_addr <= 0;   
            addr_bit_counter <= 0; 
		  end
    end

    // Armazenamento dos dados recebidos a cada borda de subida do SCL
    always @(posedge scl) begin
	     if ((uut.state == 2) || (uut.state == 4)) begin
            if (data_bit_counter < 8) begin
                received_data[7 - data_bit_counter] <= sda; // Armazena o bit dos dados recebidos
                data_bit_counter <= data_bit_counter + 1; // Incrementa o contador de bits dos dados
            end else if (data_bit_counter == 8) begin
                // Quando todos os 8 bits dos dados forem recebidos, faz a comparacao
                $display("Dados recebidos: %h", received_data);
                if (received_data == data_in) begin
                    $display("Dados corretamente recebidos.");
                end else begin
                    $display("Erro na recepcao dos dados.");
                end
                data_bit_counter <= 0; // Reseta o contador de bits dos dados
				end
        end else begin
	         received_data <= 0;   
            data_bit_counter <= 0; 
		  end
    end

endmodule
