`timescale 1ns / 1ps

module bch_decoder_15_7 (
    input  wire [14:0] codeword_in,
    output reg  [6:0]  data_out,
    output reg         err_corrected,
    output reg         uncorrectable_err,
    output reg         no_error
);
    wire [6:0] d;
    wire [7:0] p_rcv;
    wire [7:0] p_calc;
    wire [7:0] syn;
    reg  [6:0] d_corr;

    assign d     = codeword_in[6:0];
    assign p_rcv = codeword_in[14:7];

    // Standard systematic parity generator equations
    assign p_calc[0] = d[0] ^ d[2] ^ d[3] ^ d[4] ^ d[6];
    assign p_calc[1] = d[1] ^ d[3] ^ d[4] ^ d[5];
    assign p_calc[2] = d[0] ^ d[3] ^ d[5] ^ d[6];
    assign p_calc[3] = d[1] ^ d[4] ^ d[6];
    assign p_calc[4] = d[0] ^ d[3] ^ d[4] ^ d[5] ^ d[6];
    assign p_calc[5] = d[1] ^ d[4] ^ d[5] ^ d[6];
    assign p_calc[6] = d[0] ^ d[5] ^ d[6];
    assign p_calc[7] = d[1] ^ d[6];

    assign syn = p_rcv ^ p_calc;

    always @(*) begin
        d_corr            = d;
        err_corrected     = 1'b0;
        uncorrectable_err = 1'b0;
        no_error          = 1'b0;

        if (syn == 8'h00) begin
            no_error = 1'b1;
        end else begin
            // Error syndrome matching table
            case (syn)
                // Single Data Bit Errors
                8'b01010101: begin d_corr[0] = ~d[0]; err_corrected = 1'b1; end
                8'b10101010: begin d_corr[1] = ~d[1]; err_corrected = 1'b1; end
                8'b00000101: begin d_corr[2] = ~d[2]; err_corrected = 1'b1; end
                8'b00010111: begin d_corr[3] = ~d[3]; err_corrected = 1'b1; end
                8'b00110011: begin d_corr[4] = ~d[4]; err_corrected = 1'b1; end
                8'b01100110: begin d_corr[5] = ~d[5]; err_corrected = 1'b1; end
                8'b11011101: begin d_corr[6] = ~d[6]; err_corrected = 1'b1; end

                // Simultaneous Double Data Bit Errors (bit 0 & bit 1)
                (8'b01010101 ^ 8'b10101010): begin
                    d_corr[0]     = ~d[0];
                    d_corr[1]     = ~d[1];
                    err_corrected = 1'b1;
                end

                default: begin
                    // Parity bit error or uncorrectable multi-bit pattern
                    if (^syn == 1'b1)
                        err_corrected = 1'b1;
                    else
                        uncorrectable_err = 1'b1;
                end
            endcase
        end
        data_out = d_corr;
    end
endmodule