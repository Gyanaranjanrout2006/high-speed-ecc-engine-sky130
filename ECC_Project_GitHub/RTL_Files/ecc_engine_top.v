`timescale 1ns / 1ps

module ecc_engine_top (
    input  wire        clk,
    input  wire        rst_n,
    
    // Write / Encode Channel
    input  wire        encode_en,
    input  wire [31:0] data_in,
    output reg  [38:0] codeword_out,
    
    // Read / Decode Channel
    input  wire        decode_en,
    input  wire [38:0] codeword_in,
    output reg  [31:0] data_corrected,
    output reg         sec_flag,
    output reg         ded_flag,
    output reg         no_error_flag
);

    wire [38:0] enc_codeword;
    wire [31:0] dec_data;
    wire        dec_sec;
    wire        dec_ded;
    wire        dec_no_err;

    // Instantiate Sub-blocks
    ecc_encoder u_encoder (
        .data_in      (data_in),
        .codeword_out (enc_codeword)
    );

    ecc_decoder u_decoder (
        .codeword_in  (codeword_in),
        .data_out     (dec_data),
        .sec_detected (dec_sec),
        .ded_detected (dec_ded),
        .no_error     (dec_no_err)
    );

    // Pipeline Registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            codeword_out   <= 39'd0;
            data_corrected <= 32'd0;
            sec_flag       <= 1'b0;
            ded_flag       <= 1'b0;
            no_error_flag  <= 1'b0;
        end else begin
            if (encode_en) begin
                codeword_out <= enc_codeword;
            end
            if (decode_en) begin
                data_corrected <= dec_data;
                sec_flag       <= dec_sec;
                ded_flag       <= dec_ded;
                no_error_flag  <= dec_no_err;
            end
        end
    end

endmodule
