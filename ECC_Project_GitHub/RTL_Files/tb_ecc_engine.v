`timescale 1ns / 1ps

module tb_ecc_engine;
    reg         clk;
    reg         rst_n;
    reg         encode_en;
    reg  [31:0] data_in;
    wire [38:0] codeword_out;
    reg         decode_en;
    reg  [38:0] codeword_in;
    wire [31:0] data_corrected;
    wire        sec_flag;
    wire        ded_flag;
    wire        no_error_flag;

    ecc_engine_top uut (
        .clk           (clk),
        .rst_n         (rst_n),
        .encode_en     (encode_en),
        .data_in       (data_in),
        .codeword_out  (codeword_out),
        .decode_en     (decode_en),
        .codeword_in   (codeword_in),
        .data_corrected(data_corrected),
        .sec_flag      (sec_flag),
        .ded_flag      (ded_flag),
        .no_error_flag (no_error_flag)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        encode_en = 0;
        decode_en = 0;
        data_in = 32'h0;
        codeword_in = 39'h0;

        #20;
        rst_n = 1;
        #10;

        // TEST CASE 1: Normal write and read (No Error)
        data_in = 32'hA5A5_5A5A;
        encode_en = 1;
        #10;
        encode_en = 0;
        #10;
        codeword_in = codeword_out;
        decode_en = 1;
        #10;
        decode_en = 0;
        #10;

        // TEST CASE 2: Single Bit Error Injection (Flip bit 5)
        // System should auto-correct to 32'hA5A5_5A5A and set sec_flag = 1
        codeword_in = codeword_out ^ (39'b1 << 5);
        decode_en = 1;
        #10;
        decode_en = 0;
        #10;

        // TEST CASE 3: Double Bit Error Injection (Flip bit 2 and bit 10)
        // System should detect uncorrectable error and set ded_flag = 1
        codeword_in = codeword_out ^ (39'b1 << 2) ^ (39'b1 << 10);
        decode_en = 1;
        #10;
        decode_en = 0;
        #20;

        $finish;
    end
endmodule