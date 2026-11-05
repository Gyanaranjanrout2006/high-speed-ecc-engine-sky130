`timescale 1ns / 1ps

module ecc_bist_fiu_top (
    input  wire        clk,
    input  wire        rst_n,

    // Normal Operational Interface
    input  wire        normal_enc_en,
    input  wire [31:0] normal_data_in,
    input  wire        normal_dec_en,
    input  wire [38:0] normal_cw_in,
    output wire [31:0] normal_data_out,
    output wire        normal_sec,
    output wire        normal_ded,

    // BIST & Error Injection Configuration Ports
    input  wire        bist_start,          // Trigger self-test sequence
    input  wire        fiu_enable,          // 1 = Inject Fault, 0 = Normal operation
    input  wire [1:0]  fiu_mode,            // 00: Inject Bit A, 01: Inject Bit A & B, 10: Inject from LFSR
    input  wire [5:0]  fiu_bit_pos_a,       // Target bit 0-38
    input  wire [5:0]  fiu_bit_pos_b,       // Target bit 0-38

    // BIST Status & Telemetry Outputs
    output reg         bist_running,
    output reg         bist_done,
    output reg         bist_pass,
    output reg  [7:0]  bist_cycle_cnt,
    output reg  [7:0]  sec_detect_cnt,
    output reg  [7:0]  ded_detect_cnt
);

    // ==========================================
    // 32-bit LFSR (Pseudo-Random Pattern Generator)
    // ==========================================
    reg [31:0] lfsr_reg;
    wire lfsr_feedback = lfsr_reg[31] ^ lfsr_reg[21] ^ lfsr_reg[1] ^ lfsr_reg[0];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lfsr_reg <= 32'hA5A5A5A5; // Non-zero Seed
        else if (bist_running)
            lfsr_reg <= {lfsr_reg[30:0], lfsr_feedback};
    end

    // ==========================================
    // BIST FSM States
    // ==========================================
    localparam STATE_IDLE       = 3'd0;
    localparam STATE_ENCODE     = 3'd1;
    localparam STATE_INJECT     = 3'd2;
    localparam STATE_DECODE     = 3'd3;
    localparam STATE_CHECK      = 3'd4;
    localparam STATE_DONE       = 3'd5;

    reg [2:0] state;
    reg [31:0] golden_data;
    reg [38:0] raw_codeword;
    reg [38:0] corrupted_codeword;
    reg [1:0]  test_mode; // 01: Test SEC, 10: Test DED

    // ==========================================
    // Fault Injection Mask Generator
    // ==========================================
    reg [38:0] error_mask;

    always @(*) begin
        error_mask = 39'd0;
        if (fiu_enable || bist_running) begin
            if (bist_running) begin
                if (test_mode == 2'b01)
                    error_mask = (39'b1 << (lfsr_reg[4:0] % 39)); // Random Single Bit
                else if (test_mode == 2'b10)
                    error_mask = (39'b1 << (lfsr_reg[4:0] % 39)) | (39'b1 << ((lfsr_reg[4:0] + 5'd7) % 39)); // Double Bit
            end else begin
                case (fiu_mode)
                    2'b00: error_mask = (39'b1 << fiu_bit_pos_a);
                    2'b01: error_mask = (39'b1 << fiu_bit_pos_a) | (39'b1 << fiu_bit_pos_b);
                    2'b10: error_mask = (39'b1 << (lfsr_reg[5:0] % 39));
                    default: error_mask = 39'd0;
                endcase
            end
        end
    end

    // Core Interconnect Wires
    wire [31:0] core_enc_data_in = bist_running ? lfsr_reg : normal_data_in;
    wire        core_enc_en      = bist_running ? (state == STATE_ENCODE) : normal_enc_en;
    wire [38:0] core_codeword_out;

    wire [38:0] core_dec_cw_in   = bist_running ? corrupted_codeword : 
                                   (fiu_enable ? (normal_cw_in ^ error_mask) : normal_cw_in);
    wire        core_dec_en      = bist_running ? (state == STATE_DECODE) : normal_dec_en;
    wire [31:0] core_data_corrected;
    wire        core_sec;
    wire        core_ded;
    wire        core_no_error;

    // Direct assignment to normal operational outputs
    assign normal_data_out = core_data_corrected;
    assign normal_sec      = core_sec;
    assign normal_ded      = core_ded;

    // Instantiate Base SEC-DED Core
    ecc_engine_top u_ecc_core (
        .clk           (clk),
        .rst_n         (rst_n),
        .encode_en     (core_enc_en),
        .data_in       (core_enc_data_in),
        .codeword_out  (core_codeword_out),
        .decode_en     (core_dec_en),
        .codeword_in   (core_dec_cw_in),
        .data_corrected(core_data_corrected),
        .sec_flag      (core_sec),
        .ded_flag      (core_ded),
        .no_error_flag (core_no_error)
    );

    // ==========================================
    // BIST Autonomous Execution & Self-Checking FSM
    // ==========================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= STATE_IDLE;
            bist_running   <= 1'b0;
            bist_done      <= 1'b0;
            bist_pass      <= 1'b1;
            bist_cycle_cnt <= 8'd0;
            sec_detect_cnt <= 8'd0;
            ded_detect_cnt <= 8'd0;
            golden_data    <= 32'd0;
            raw_codeword   <= 39'd0;
            corrupted_codeword <= 39'd0;
            test_mode      <= 2'b01;
        end else begin
            case (state)
                STATE_IDLE: begin
                    bist_done <= 1'b0;
                    if (bist_start) begin
                        bist_running   <= 1'b1;
                        bist_pass      <= 1'b1;
                        bist_cycle_cnt <= 8'd0;
                        sec_detect_cnt <= 8'd0;
                        ded_detect_cnt <= 8'd0;
                        test_mode      <= 2'b01; // First phase: SEC Test
                        state          <= STATE_ENCODE;
                    end
                end

                STATE_ENCODE: begin
                    golden_data  <= lfsr_reg;
                    raw_codeword <= core_codeword_out;
                    state        <= STATE_INJECT;
                end

                STATE_INJECT: begin
                    corrupted_codeword <= raw_codeword ^ error_mask;
                    state              <= STATE_DECODE;
                end

                STATE_DECODE: begin
                    state <= STATE_CHECK;
                end

                STATE_CHECK: begin
                    bist_cycle_cnt <= bist_cycle_cnt + 1'b1;

                    // Verify SEC behavior (Must correct data AND raise sec_flag)
                    if (test_mode == 2'b01) begin
                        if (core_sec && (core_data_corrected == golden_data))
                            sec_detect_cnt <= sec_detect_cnt + 1'b1;
                        else
                            bist_pass <= 1'b0; // Fault injection failed!
                    end

                    // Verify DED behavior (Must flag uncorrectable double error)
                    if (test_mode == 2'b10) begin
                        if (core_ded)
                            ded_detect_cnt <= ded_detect_cnt + 1'b1;
                        else
                            bist_pass <= 1'b0;
                    end

                    // 16 cycles of SEC tests + 16 cycles of DED tests
                    if (bist_cycle_cnt < 8'd16) begin
                        test_mode <= 2'b01;
                        state     <= STATE_ENCODE;
                    end else if (bist_cycle_cnt < 8'd32) begin
                        test_mode <= 2'b10;
                        state     <= STATE_ENCODE;
                    end else begin
                        state <= STATE_DONE;
                    end
                end

                STATE_DONE: begin
                    bist_running <= 1'b0;
                    bist_done    <= 1'b1;
                    state        <= STATE_IDLE;
                end

                default: state <= STATE_IDLE;
            endcase
        end
    end

endmodule