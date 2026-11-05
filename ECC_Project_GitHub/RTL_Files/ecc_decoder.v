`timescale 1ns / 1ps

module ecc_decoder (
    input  wire [38:0] codeword_in,
    output reg  [31:0] data_out,
    output reg         sec_detected,  // Single Error Corrected
    output reg         ded_detected,  // Double Error Detected (Uncorrectable)
    output reg         no_error
);

    wire [31:0] d;
    wire [5:0]  p_received;
    wire        p_ext_received;
    wire [5:0]  p_calculated;
    wire [5:0]  syndrome;
    wire        parity_match;

    assign d              = codeword_in[31:0];
    assign p_received     = codeword_in[37:32];
    assign p_ext_received = codeword_in[38];

    // Recalculate parity from incoming data bits
    assign p_calculated[0] = d[0]  ^ d[1]  ^ d[3]  ^ d[4]  ^ d[6]  ^ d[8]  ^ 
                             d[10] ^ d[11] ^ d[13] ^ d[15] ^ d[17] ^ d[19] ^ 
                             d[21] ^ d[23] ^ d[25] ^ d[26] ^ d[28] ^ d[30];

    assign p_calculated[1] = d[0]  ^ d[2]  ^ d[3]  ^ d[5]  ^ d[6]  ^ d[9]  ^ 
                             d[10] ^ d[12] ^ d[13] ^ d[16] ^ d[17] ^ d[20] ^ 
                             d[21] ^ d[24] ^ d[25] ^ d[27] ^ d[28] ^ d[31];

    assign p_calculated[2] = d[1]  ^ d[2]  ^ d[3]  ^ d[7]  ^ d[8]  ^ d[9]  ^ 
                             d[10] ^ d[14] ^ d[15] ^ d[16] ^ d[17] ^ d[22] ^ 
                             d[23] ^ d[24] ^ d[25] ^ d[29] ^ d[30] ^ d[31];

    assign p_calculated[3] = d[4]  ^ d[5]  ^ d[6]  ^ d[7]  ^ d[8]  ^ d[9]  ^ 
                             d[10] ^ d[18] ^ d[19] ^ d[20] ^ d[21] ^ d[22] ^ 
                             d[23] ^ d[24] ^ d[25];

    assign p_calculated[4] = d[11] ^ d[12] ^ d[13] ^ d[14] ^ d[15] ^ d[16] ^ 
                             d[17] ^ d[18] ^ d[19] ^ d[20] ^ d[21] ^ d[22] ^ 
                             d[23] ^ d[24] ^ d[25];

    assign p_calculated[5] = d[26] ^ d[27] ^ d[28] ^ d[29] ^ d[30] ^ d[31];

    // Syndrome generation (received XOR calculated)
    assign syndrome = p_received ^ p_calculated;

    // Check full codeword parity
    assign parity_match = (p_ext_received == (^d ^ (^p_received)));

    always @(*) begin
        data_out     = d;
        sec_detected = 1'b0;
        ded_detected = 1'b0;
        no_error     = 1'b0;

        if (syndrome == 6'b000000) begin
            if (parity_match) begin
                no_error = 1'b1;
            end else begin
                // Error in overall parity bit itself
                sec_detected = 1'b1;
            end
        end else begin
            if (!parity_match) begin
                // Odd parity mismatch + non-zero syndrome = Single-bit error in data/parity
                sec_detected = 1'b1;
                case (syndrome)
                    6'd3:  data_out[0]  = ~d[0];
                    6'd5:  data_out[1]  = ~d[1];
                    6'd6:  data_out[2]  = ~d[2];
                    6'd7:  data_out[3]  = ~d[3];
                    6'd9:  data_out[4]  = ~d[4];
                    6'd10: data_out[5]  = ~d[5];
                    6'd11: data_out[6]  = ~d[6];
                    6'd12: data_out[7]  = ~d[7];
                    6'd13: data_out[8]  = ~d[8];
                    6'd14: data_out[9]  = ~d[9];
                    6'd15: data_out[10] = ~d[10];
                    6'd17: data_out[11] = ~d[11];
                    6'd18: data_out[12] = ~d[12];
                    6'd19: data_out[13] = ~d[13];
                    6'd20: data_out[14] = ~d[14];
                    6'd21: data_out[15] = ~d[15];
                    6'd22: data_out[16] = ~d[16];
                    6'd23: data_out[17] = ~d[17];
                    6'd25: data_out[18] = ~d[18];
                    6'd26: data_out[19] = ~d[19];
                    6'd27: data_out[20] = ~d[20];
                    6'd28: data_out[21] = ~d[21];
                    6'd29: data_out[22] = ~d[22];
                    6'd30: data_out[23] = ~d[23];
                    6'd31: data_out[24] = ~d[24];
                    6'd33: data_out[25] = ~d[25];
                    6'd34: data_out[26] = ~d[26];
                    6'd35: data_out[27] = ~d[27];
                    6'd36: data_out[28] = ~d[28];
                    6'd37: data_out[29] = ~d[29];
                    6'd38: data_out[30] = ~d[30];
                    6'd39: data_out[31] = ~d[31];
                    default: ; // Single bit error in parity bit (data stays intact)
                endcase
            end else begin
                // Even parity match + non-zero syndrome = Double-bit Error (Uncorrectable)
                ded_detected = 1'b1;
            end
        end
    end

endmodule
