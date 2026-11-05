`timescale 1ns / 1ps

module bch_engine_top (
    input  wire        clk,
    input  wire        rst_n,
    
    // Encode Interface
    input  wire        enc_valid,
    input  wire [6:0]  data_in,
    output reg  [14:0] codeword_out,
    
    // Decode Interface
    input  wire        dec_valid,
    input  wire [14:0] codeword_in,
    output reg  [6:0]  data_corrected,
    output reg         err_corrected_flag,
    output reg         uncorrectable_flag,
    output reg         no_error_flag
);

    wire [14:0] enc_cw;
    wire [6:0]  dec_data;
    wire        dec_err_corr;
    wire        dec_uncorr;
    wire        dec_no_err;

    bch_encoder_15_7 u_encoder (
        .data_in      (data_in),
        .codeword_out (enc_cw)
    );

    bch_decoder_15_7 u_decoder (
        .codeword_in       (codeword_in),
        .data_out          (dec_data),
        .err_corrected     (dec_err_corr),
        .uncorrectable_err (dec_uncorr),
        .no_error          (dec_no_err)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            codeword_out       <= 15'd0;
            data_corrected     <= 7'd0;
            err_corrected_flag <= 1'b0;
            uncorrectable_flag <= 1'b0;
            no_error_flag      <= 1'b0;
        end else begin
            if (enc_valid) begin
                codeword_out <= enc_cw;
            end
            if (dec_valid) begin
                data_corrected     <= dec_data;
                err_corrected_flag <= dec_err_corr;
                uncorrectable_flag <= dec_uncorr;
                no_error_flag      <= dec_no_err;
            end
        end
    end

endmodule