`timescale 1ns / 1ps

module tb_ecc_pipelined;
    reg         clk;
    reg         rst_n;
    reg         enc_valid;
    reg  [31:0] enc_data_in;
    wire        enc_valid_out;
    wire [38:0] enc_codeword_out;

    reg         dec_valid;
    reg  [38:0] dec_codeword_in;
    wire        dec_valid_out;
    wire [31:0] dec_data_out;
    wire        sec_flag_out;
    wire        ded_flag_out;
    wire        no_error_flag_out;

    ecc_pipelined_top uut (
        .clk              (clk),
        .rst_n            (rst_n),
        .enc_valid        (enc_valid),
        .enc_data_in      (enc_data_in),
        .enc_valid_out    (enc_valid_out),
        .enc_codeword_out (enc_codeword_out),
        .dec_valid        (dec_valid),
        .dec_codeword_in  (dec_codeword_in),
        .dec_valid_out    (dec_valid_out),
        .dec_data_out     (dec_data_out),
        .sec_flag_out     (sec_flag_out),
        .ded_flag_out     (ded_flag_out),
        .no_error_flag_out(no_error_flag_out)
    );

    // High frequency clock: 200 MHz (Period = 5 ns)
    always #2.5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        enc_valid = 0;
        enc_data_in = 32'h0;
        dec_valid = 0;
        dec_codeword_in = 39'h0;

        #20;
        rst_n = 1;
        #10;

        // Step 1: Encode a packet
        enc_data_in = 32'hBEEFBEEF;
        enc_valid = 1;
        #5;
        enc_valid = 0;

        // Wait for encode output
        @(posedge enc_valid_out);
        #5;

        // Step 2: Inject back-to-back streaming packets into 3-stage decoder pipeline
        // Packet A: Clean (No Error)
        dec_codeword_in = enc_codeword_out;
        dec_valid = 1;
        #5;

        // Packet B: Single Bit Error (Flip Bit 7)
        dec_codeword_in = enc_codeword_out ^ (39'b1 << 7);
        dec_valid = 1;
        #5;

        // Packet C: Double Bit Error (Flip Bit 2 & Bit 12)
        dec_codeword_in = enc_codeword_out ^ (39'b1 << 2) ^ (39'b1 << 12);
        dec_valid = 1;
        #5;

        dec_valid = 0;

        // Observe continuous 3-cycle pipeline streaming
        #50;
        $finish;
    end
endmodule
