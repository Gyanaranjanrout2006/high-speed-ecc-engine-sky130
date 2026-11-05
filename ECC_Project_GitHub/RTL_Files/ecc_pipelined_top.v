`timescale 1ns / 1ps

module ecc_pipelined_top (
    input  wire        clk,
    input  wire        rst_n,

    // Encoder Port (1-Cycle Latency)
    input  wire        enc_valid,
    input  wire [31:0] enc_data_in,
    output reg         enc_valid_out,
    output reg  [38:0] enc_codeword_out,

    // Decoder Port (3-Stage Pipeline Latency)
    input  wire        dec_valid,
    input  wire [38:0] dec_codeword_in,
    output reg         dec_valid_out,
    output reg  [31:0] dec_data_out,
    output reg         sec_flag_out,
    output reg         ded_flag_out,
    output reg         no_error_flag_out
);

    // ==========================================
    // ENCODER LOGIC (Registered)
    // ==========================================
    wire [5:0]  enc_p;
    wire        enc_p_ext;
    wire [38:0] enc_cw_comb;

    assign enc_p[0] = enc_data_in[0]  ^ enc_data_in[1]  ^ enc_data_in[3]  ^ enc_data_in[4]  ^ 
                      enc_data_in[6]  ^ enc_data_in[8]  ^ enc_data_in[10] ^ enc_data_in[11] ^ 
                      enc_data_in[13] ^ enc_data_in[15] ^ enc_data_in[17] ^ enc_data_in[19] ^ 
                      enc_data_in[21] ^ enc_data_in[23] ^ enc_data_in[25] ^ enc_data_in[26] ^ 
                      enc_data_in[28] ^ enc_data_in[30];

    assign enc_p[1] = enc_data_in[0]  ^ enc_data_in[2]  ^ enc_data_in[3]  ^ enc_data_in[5]  ^ 
                      enc_data_in[6]  ^ enc_data_in[9]  ^ enc_data_in[10] ^ enc_data_in[12] ^ 
                      enc_data_in[13] ^ enc_data_in[16] ^ enc_data_in[17] ^ enc_data_in[20] ^ 
                      enc_data_in[21] ^ enc_data_in[24] ^ enc_data_in[25] ^ enc_data_in[27] ^ 
                      enc_data_in[28] ^ enc_data_in[31];

    assign enc_p[2] = enc_data_in[1]  ^ enc_data_in[2]  ^ enc_data_in[3]  ^ enc_data_in[7]  ^ 
                      enc_data_in[8]  ^ enc_data_in[9]  ^ enc_data_in[10] ^ enc_data_in[14] ^ 
                      enc_data_in[15] ^ enc_data_in[16] ^ enc_data_in[17] ^ enc_data_in[22] ^ 
                      enc_data_in[23] ^ enc_data_in[24] ^ enc_data_in[25] ^ enc_data_in[29] ^ 
                      enc_data_in[30] ^ enc_data_in[31];

    assign enc_p[3] = enc_data_in[4]  ^ enc_data_in[5]  ^ enc_data_in[6]  ^ enc_data_in[7]  ^ 
                      enc_data_in[8]  ^ enc_data_in[9]  ^ enc_data_in[10] ^ enc_data_in[18] ^ 
                      enc_data_in[19] ^ enc_data_in[20] ^ enc_data_in[21] ^ enc_data_in[22] ^ 
                      enc_data_in[23] ^ enc_data_in[24] ^ enc_data_in[25];

    assign enc_p[4] = enc_data_in[11] ^ enc_data_in[12] ^ enc_data_in[13] ^ enc_data_in[14] ^ 
                      enc_data_in[15] ^ enc_data_in[16] ^ enc_data_in[17] ^ enc_data_in[18] ^ 
                      enc_data_in[19] ^ enc_data_in[20] ^ enc_data_in[21] ^ enc_data_in[22] ^ 
                      enc_data_in[23] ^ enc_data_in[24] ^ enc_data_in[25];

    assign enc_p[5] = enc_data_in[26] ^ enc_data_in[27] ^ enc_data_in[28] ^ enc_data_in[29] ^ 
                      enc_data_in[30] ^ enc_data_in[31];

    assign enc_p_ext = ^enc_data_in ^ (^enc_p);
    assign enc_cw_comb = {enc_p_ext, enc_p, enc_data_in};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enc_valid_out    <= 1'b0;
            enc_codeword_out <= 39'd0;
        end else begin
            enc_valid_out    <= enc_valid;
            if (enc_valid)
                enc_codeword_out <= enc_cw_comb;
        end
    end

    // ==========================================
    // DECODER: STAGE 1 (Syndrome Generation)
    // ==========================================
    wire [31:0] s1_d           = dec_codeword_in[31:0];
    wire [5:0]  s1_p_rcv       = dec_codeword_in[37:32];
    wire        s1_pext_rcv    = dec_codeword_in[38];

    wire [5:0]  s1_p_calc;
    assign s1_p_calc[0] = s1_d[0]  ^ s1_d[1]  ^ s1_d[3]  ^ s1_d[4]  ^ s1_d[6]  ^ s1_d[8]  ^ 
                          s1_d[10] ^ s1_d[11] ^ s1_d[13] ^ s1_d[15] ^ s1_d[17] ^ s1_d[19] ^ 
                          s1_d[21] ^ s1_d[23] ^ s1_d[25] ^ s1_d[26] ^ s1_d[28] ^ s1_d[30];

    assign s1_p_calc[1] = s1_d[0]  ^ s1_d[2]  ^ s1_d[3]  ^ s1_d[5]  ^ s1_d[6]  ^ s1_d[9]  ^ 
                          s1_d[10] ^ s1_d[12] ^ s1_d[13] ^ s1_d[16] ^ s1_d[17] ^ s1_d[20] ^ 
                          s1_d[21] ^ s1_d[24] ^ s1_d[25] ^ s1_d[27] ^ s1_d[28] ^ s1_d[31];

    assign s1_p_calc[2] = s1_d[1]  ^ s1_d[2]  ^ s1_d[3]  ^ s1_d[7]  ^ s1_d[8]  ^ s1_d[9]  ^ 
                          s1_d[10] ^ s1_d[14] ^ s1_d[15] ^ s1_d[16] ^ s1_d[17] ^ s1_d[22] ^ 
                          s1_d[23] ^ s1_d[24] ^ s1_d[25] ^ s1_d[29] ^ s1_d[30] ^ s1_d[31];

    assign s1_p_calc[3] = s1_d[4]  ^ s1_d[5]  ^ s1_d[6]  ^ s1_d[7]  ^ s1_d[8]  ^ s1_d[9]  ^ 
                          s1_d[10] ^ s1_d[18] ^ s1_d[19] ^ s1_d[20] ^ s1_d[21] ^ s1_d[22] ^ 
                          s1_d[23] ^ s1_d[24] ^ s1_d[25];

    assign s1_p_calc[4] = s1_d[11] ^ s1_d[12] ^ s1_d[13] ^ s1_d[14] ^ s1_d[15] ^ s1_d[16] ^ 
                          s1_d[17] ^ s1_d[18] ^ s1_d[19] ^ s1_d[20] ^ s1_d[21] ^ s1_d[22] ^ 
                          s1_d[23] ^ s1_d[24] ^ s1_d[25];

    assign s1_p_calc[5] = s1_d[26] ^ s1_d[27] ^ s1_d[28] ^ s1_d[29] ^ s1_d[30] ^ s1_d[31];

    wire [5:0] s1_syn_comb  = s1_p_rcv ^ s1_p_calc;
    wire       s1_par_match = (s1_pext_rcv == (^s1_d ^ (^s1_p_rcv)));

    // Pipeline Register 1
    reg        pipe1_valid;
    reg [31:0] pipe1_data;
    reg [5:0]  pipe1_syn;
    reg        pipe1_par_match;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe1_valid     <= 1'b0;
            pipe1_data      <= 32'd0;
            pipe1_syn       <= 6'd0;
            pipe1_par_match <= 1'b0;
        end else begin
            pipe1_valid     <= dec_valid;
            pipe1_data      <= s1_d;
            pipe1_syn       <= s1_syn_comb;
            pipe1_par_match <= s1_par_match;
        end
    end

    // ==========================================
    // DECODER: STAGE 2 (Error Vector Decoding)
    // ==========================================
    reg [31:0] s2_mask_comb;
    reg        s2_sec_comb;
    reg        s2_ded_comb;
    reg        s2_noerr_comb;

    always @(*) begin
        s2_mask_comb  = 32'h0;
        s2_sec_comb   = 1'b0;
        s2_ded_comb   = 1'b0;
        s2_noerr_comb = 1'b0;

        if (pipe1_syn == 6'b000000) begin
            if (pipe1_par_match)
                s2_noerr_comb = 1'b1;
            else
                s2_sec_comb   = 1'b1; // Overall parity bit error
        end else begin
            if (!pipe1_par_match) begin
                s2_sec_comb = 1'b1;
                case (pipe1_syn)
                    6'd3:  s2_mask_comb[0]  = 1'b1;
                    6'd5:  s2_mask_comb[1]  = 1'b1;
                    6'd6:  s2_mask_comb[2]  = 1'b1;
                    6'd7:  s2_mask_comb[3]  = 1'b1;
                    6'd9:  s2_mask_comb[4]  = 1'b1;
                    6'd10: s2_mask_comb[5]  = 1'b1;
                    6'd11: s2_mask_comb[6]  = 1'b1;
                    6'd12: s2_mask_comb[7]  = 1'b1;
                    6'd13: s2_mask_comb[8]  = 1'b1;
                    6'd14: s2_mask_comb[9]  = 1'b1;
                    6'd15: s2_mask_comb[10] = 1'b1;
                    6'd17: s2_mask_comb[11] = 1'b1;
                    6'd18: s2_mask_comb[12] = 1'b1;
                    6'd19: s2_mask_comb[13] = 1'b1;
                    6'd20: s2_mask_comb[14] = 1'b1;
                    6'd21: s2_mask_comb[15] = 1'b1;
                    6'd22: s2_mask_comb[16] = 1'b1;
                    6'd23: s2_mask_comb[17] = 1'b1;
                    6'd25: s2_mask_comb[18] = 1'b1;
                    6'd26: s2_mask_comb[19] = 1'b1;
                    6'd27: s2_mask_comb[20] = 1'b1;
                    6'd28: s2_mask_comb[21] = 1'b1;
                    6'd29: s2_mask_comb[22] = 1'b1;
                    6'd30: s2_mask_comb[23] = 1'b1;
                    6'd31: s2_mask_comb[24] = 1'b1;
                    6'd33: s2_mask_comb[25] = 1'b1;
                    6'd34: s2_mask_comb[26] = 1'b1;
                    6'd35: s2_mask_comb[27] = 1'b1;
                    6'd36: s2_mask_comb[28] = 1'b1;
                    6'd37: s2_mask_comb[29] = 1'b1;
                    6'd38: s2_mask_comb[30] = 1'b1;
                    6'd39: s2_mask_comb[31] = 1'b1;
                    default: ;
                endcase
            end else begin
                s2_ded_comb = 1'b1;
            end
        end
    end

    // Pipeline Register 2
    reg        pipe2_valid;
    reg [31:0] pipe2_data;
    reg [31:0] pipe2_mask;
    reg        pipe2_sec;
    reg        pipe2_ded;
    reg        pipe2_noerr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pipe2_valid <= 1'b0;
            pipe2_data  <= 32'd0;
            pipe2_mask  <= 32'd0;
            pipe2_sec   <= 1'b0;
            pipe2_ded   <= 1'b0;
            pipe2_noerr <= 1'b0;
        end else begin
            pipe2_valid <= pipe1_valid;
            pipe2_data  <= pipe1_data;
            pipe2_mask  <= s2_mask_comb;
            pipe2_sec   <= s2_sec_comb;
            pipe2_ded   <= s2_ded_comb;
            pipe2_noerr <= s2_noerr_comb;
        end
    end

    // ==========================================
    // DECODER: STAGE 3 (Correction & Final Out)
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dec_valid_out     <= 1'b0;
            dec_data_out      <= 32'd0;
            sec_flag_out      <= 1'b0;
            ded_flag_out      <= 1'b0;
            no_error_flag_out <= 1'b0;
        end else begin
            dec_valid_out     <= pipe2_valid;
            dec_data_out      <= pipe2_data ^ pipe2_mask; // High-speed parallel bit flip
            sec_flag_out      <= pipe2_sec;
            ded_flag_out      <= pipe2_ded;
            no_error_flag_out <= pipe2_noerr;
        end
    end

endmodule