`timescale 1ns / 1ps

module tb_uart_rx;

    // --- Signals ---
    reg clk;
    reg reset;
    reg rx;
    wire [7:0] data_out;
    wire rx_done;

    // --- Simulation Parameters ---
    // Período do clock de 12MHz: 1 / 12MHz ≈ 83.33ns
	localparam CLK_PERIOD = 83; 
	
	// Assumindo 9600 baud rate e 12 MHz clock
	// Em ciclos de clock de 12MHz: 12.000.000 / 9600 = 1250 ciclos.
	localparam CLK_PER_BIT = 16'd1250;

	// Para 9600 baud, o período do bit é 1 / 9600 = 104.166,67 ns ~ 104
	// Período de 1 bit: 1250 ciclos * 83ns ≈ 103,750ns (próximo dos 104 us do 9600 baud)
    localparam BIT_PERIOD = CLK_PERIOD * CLK_PER_BIT;

    // --- Internal Verification Register ---
    reg [7:0] expected_data;

    // --- UUT Instantiation ---
    uart_rx uut (
        .clk(clk),
        .reset(reset),
        .rx(rx),
        .data_out(data_out),
        .rx_done(rx_done)
    );

    // --- Clock Generation ---
    always #(CLK_PERIOD / 2) clk = ~clk;

    // --- Main Test Sequence ---
    initial begin
        // 1. Initialize
        clk = 0;
        reset = 1;
        rx = 1; 
        expected_data = 8'h00;

        $display("---------------------------------------------------------");
        $display("Starting UART RX Testbench...");
        $display("---------------------------------------------------------");

        #(CLK_PERIOD * 5) reset = 0;
        #(CLK_PERIOD * 5);

        // Test 1: Standard Byte
        send_byte(8'hA5);
        verify_result();

        // Test 2: Another Byte
        send_byte(8'h3C);
        verify_result();

        // Test 3: All Zeros
        send_byte(8'h00);
        verify_result();

        // Test 4: Error Injection (Stop bit is 0 instead of 1)
        $display("Time = %0t: Injecting Stop Bit Error...", $time);
        send_byte_with_error(8'hFF);
        // Note: Depending on your RX design, rx_done might not trigger 
        // or it might trigger with an error flag.
        
        #BIT_PERIOD;
        $display("---------------------------------------------------------");
        $display("Simulation Finished.");
        $display("---------------------------------------------------------");
        $stop;
    end

    // --- Verification Task ---
    task verify_result;
        begin
            wait(rx_done);
            if (data_out === expected_data)
                $display("[PASS] Time = %0t | Sent: %h | Received: %h", $time, expected_data, data_out);
            else
                $display("[FAIL] Time = %0t | Sent: %h | Received: %h", $time, expected_data, data_out);
            
            // Small delay to clear the rx_done pulse in simulation
            #(CLK_PERIOD * 2);
        end
    endtask

    // --- Task: Send a Byte (Correct UART Protocol) ---
    task send_byte(input [7:0] byte_to_send);
        integer i;
        begin
            expected_data = byte_to_send;
            $display("[TX Simulation] Sending Byte: %h", byte_to_send);
            
            // Start bit
            rx = 0;
            #(BIT_PERIOD);
            
            // 8 Data bits (LSB first)
            for (i = 0; i < 8; i = i + 1) begin
                rx = byte_to_send[i];
                #(BIT_PERIOD);
            end
            
            // Stop bit
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // --- Task: Send a Byte with Framing Error ---
    task send_byte_with_error(input [7:0] byte_to_send);
        integer i;
        begin
            expected_data = byte_to_send;
            // Start bit
            rx = 0;
            #(BIT_PERIOD);
            
            for (i = 0; i < 8; i = i + 1) begin
                rx = byte_to_send[i];
                #(BIT_PERIOD);
            end
            
            // INCORRECT Stop bit (forcing 0)
            rx = 0; 
            #(BIT_PERIOD);
            
            // Return to Idle
            rx = 1;
            #(BIT_PERIOD);
        end
    endtask

    // --- Monitor ---
    initial begin
        $monitor("Time=%0t | RX=%b | State=%b | DataOut=%h | Done=%b", 
                 $time, rx, uut.state, data_out, rx_done);
    end

endmodule