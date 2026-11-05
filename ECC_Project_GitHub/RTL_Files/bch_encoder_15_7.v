`timescale 1ns / 1ps

module bch_encoder_15_7 (
    input  wire [6:0]  data_in,
    output wire [14:0] codeword_out
);
    wire [7:0] p;

    // Parallel LFSR XOR equations derived from g(x) = x^8 + x^7 + x^6 + x^4 + 1
    assign p[0] = data_in[0] ^ data_in[2] ^ data_in[3] ^ data_in[4] ^ data_in[6];
    assign p[1] = data_in[1] ^ data_in[3] ^ data_in[4] ^ data_in[5];
    assign p[2] = data_in[0] ^ data_in[3] ^ data_in[5] ^ data_in[6];
    assign p[3] = data_in[1] ^ data_in[4] ^ data_in[6];
    assign p[4] = data_in[0] ^ data_in[3] ^ data_in[4] ^ data_in[5] ^ data_in[6];
    assign p[5] = data_in[1] ^ data_in[4] ^ data_in[5] ^ data_in[6];
    assign p[6] = data_in[0] ^ data_in[5] ^ data_in[6];
    assign p[7] = data_in[1] ^ data_in[6];

    // Systematic codeword: {parity[7:0], data[6:0]}
    assign codeword_out = {p, data_in};

endmodule
