`timescale 1ns / 1ps

module tb_bch_engine;
    reg        clk;
    reg        rst_n;
    reg        enc_valid;
    reg  [6:0] data_in;
    wire [14:0] codeword_out;
    reg        dec_valid;
    reg  [14:0] codeword_in;
    wire [6:0] data_corrected;
    wire       err_corrected_flag;
    wire       uncorrectable_flag;
    wire       no_error_flag;

    bch_engine_top uut (
        .clk               (clk),
        .rst_n             (rst_n),
        .enc_valid         (enc_valid),
        .data_in           (data_in),
        .codeword_out      (codeword_out),
        .dec_valid         (dec_valid),
        .codeword_in       (codeword_in),
        .data_corrected    (data_corrected),
        .err_corrected_flag(err_corrected_flag),
        .uncorrectable_flag(uncorrectable_flag),
        .no_error_flag     (no_error_flag)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0;
        rst_n = 0;
        enc_valid = 0;
        dec_valid = 0;
        data_in = 7'h0;
        codeword_in = 15'h0;

        #20;
        rst_n = 1;
        #10;

        // Case 1: Encode data 7'b1010101
        data_in = 7'b1010101;
        enc_valid = 1;
        #10;
        enc_valid = 0;
        #10;

        // Case 2: Clean Read (No Error)
        codeword_in = codeword_out;
        dec_valid = 1;
        #10;
        dec_valid = 0;
        #10;

        // Case 3: SIMULTANEOUS DOUBLE-BIT ERROR (Flip bit 0 AND bit 1)
        // BCH engine should automatically recover both bits to 7'b1010101!
        codeword_in = codeword_out ^ 15'b000000000000011;
        dec_valid = 1;
        #10;
        dec_valid = 0;
        #20;

        $finish;
    end
endmodule