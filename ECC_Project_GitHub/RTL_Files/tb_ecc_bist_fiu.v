`timescale 1ns / 1ps

module tb_ecc_bist_fiu;
    reg         clk;
    reg         rst_n;

    // Normal Interface
    reg         normal_enc_en;
    reg  [31:0] normal_data_in;
    reg         normal_dec_en;
    reg  [38:0] normal_cw_in;
    wire [31:0] normal_data_out;
    wire        normal_sec;
    wire        normal_ded;

    // BIST & FIU
    reg         bist_start;
    reg         fiu_enable;
    reg  [1:0]  fiu_mode;
    reg  [5:0]  fiu_bit_pos_a;
    reg  [5:0]  fiu_bit_pos_b;

    wire        bist_running;
    wire        bist_done;
    wire        bist_pass;
    wire [7:0]  bist_cycle_cnt;
    wire [7:0]  sec_detect_cnt;
    wire [7:0]  ded_detect_cnt;

    ecc_bist_fiu_top uut (
        .clk              (clk),
        .rst_n            (rst_n),
        .normal_enc_en    (normal_enc_en),
        .normal_data_in   (normal_data_in),
        .normal_dec_en    (normal_dec_en),
        .normal_cw_in     (normal_cw_in),
        .normal_data_out  (normal_data_out),
        .normal_sec       (normal_sec),
        .normal_ded       (normal_ded),
        .bist_start       (bist_start),
        .fiu_enable       (fiu_enable),
        .fiu_mode         (fiu_mode),
        .fiu_bit_pos_a    (fiu_bit_pos_a),
        .fiu_bit_pos_b    (fiu_bit_pos_b),
        .bist_running     (bist_running),
        .bist_done        (bist_done),
        .bist_pass        (bist_pass),
        .bist_cycle_cnt   (bist_cycle_cnt),
        .sec_detect_cnt   (sec_detect_cnt),
        .ded_detect_cnt   (ded_detect_cnt)
    );

    always #5 clk = ~clk;

    initial begin
        clk           = 0;
        rst_n         = 0;
        normal_enc_en = 0;
        normal_data_in= 0;
        normal_dec_en = 0;
        normal_cw_in  = 0;
        bist_start    = 0;
        fiu_enable    = 0;
        fiu_mode      = 0;
        fiu_bit_pos_a = 0;
        fiu_bit_pos_b = 0;

        #20;
        rst_n = 1;
        #20;

        // ===============================================
        // Test 1: Trigger Autonomous BIST Sequence
        // ===============================================
        bist_start = 1;
        #10;
        bist_start = 0;

        // Wait until BIST completes 32 iterations
        wait (bist_done);
        #20;

        if (bist_pass)
            $display("[BIST SUCCESS] All Single and Double bit faults correctly detected and corrected!");
        else
            $display("[BIST FAILURE] Core failed self-diagnostic check!");

        #50;
        $finish;
    end
endmodule