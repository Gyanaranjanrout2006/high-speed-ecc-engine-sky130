`timescale 1ns / 1ps

module axi_ecc_engine (
    // Global Clock & Reset (Active Low)
    input  wire        s_axi_aclk,
    input  wire        s_axi_aresetn,

    // AXI4-Lite Write Address Channel
    input  wire [31:0] s_axi_awaddr,
    input  wire [2:0]  s_axi_awprot,
    input  wire        s_axi_awvalid,
    output reg         s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [31:0] s_axi_wdata,
    input  wire [3:0]  s_axi_wstrb,
    input  wire        s_axi_wvalid,
    output reg         s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]  s_axi_bresp,
    output reg         s_axi_bvalid,
    input  wire        s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [31:0] s_axi_araddr,
    input  wire [2:0]  s_axi_arprot,
    input  wire        s_axi_arvalid,
    output reg         s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [31:0] s_axi_rdata,
    output reg  [1:0]  s_axi_rresp,
    output reg         s_axi_rvalid,
    input  wire        s_axi_rready
);

    // Internal Memory Mapped Registers
    reg [31:0] reg_data_in;
    reg [31:0] reg_codeword_low;
    reg [6:0]  reg_codeword_high; // [38:32]
    reg [1:0]  reg_ctrl;          // bit 0: encode_en, bit 1: decode_en

    // ECC Engine Interconnect Wires
    wire [38:0] ecc_codeword_out;
    wire [31:0] ecc_data_corrected;
    wire        sec_flag;
    wire        ded_flag;
    wire        no_error_flag;

    // Instantiate core ECC Engine
    ecc_engine_top u_ecc_core (
        .clk           (s_axi_aclk),
        .rst_n         (s_axi_aresetn),
        .encode_en     (reg_ctrl[0]),
        .data_in       (reg_data_in),
        .codeword_out  (ecc_codeword_out),
        .decode_en     (reg_ctrl[1]),
        .codeword_in   ({reg_codeword_high, reg_codeword_low}),
        .data_corrected(ecc_data_corrected),
        .sec_flag      (sec_flag),
        .ded_flag      (ded_flag),
        .no_error_flag (no_error_flag)
    );

    // ==========================================
    // AXI4-Lite Write Channel Handshake & Logic
    // ==========================================
    reg [31:0] axi_awaddr_reg;
    reg        aw_en;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00; // OKAY response
            aw_en         <= 1'b1;
            reg_data_in       <= 32'h0;
            reg_codeword_low  <= 32'h0;
            reg_codeword_high <= 7'h0;
            reg_ctrl          <= 2'b00;
        end else begin
            // Write Address Ready logic
            if (~s_axi_awready && s_axi_awvalid && s_axi_wvalid && aw_en) begin
                s_axi_awready  <= 1'b1;
                s_axi_wready   <= 1'b1;
                axi_awaddr_reg <= s_axi_awaddr;
                aw_en          <= 1'b0;
            end else begin
                s_axi_awready  <= 1'b0;
                s_axi_wready   <= 1'b0;
            end

            // Write Data Execution
            if (s_axi_wready && s_axi_wvalid && s_axi_awready && s_axi_awvalid) begin
                case (s_axi_awaddr[7:0])
                    8'h00: reg_data_in       <= s_axi_wdata;
                    8'h04: reg_codeword_low  <= s_axi_wdata;
                    8'h08: reg_codeword_high <= s_axi_wdata[6:0];
                    8'h10: reg_ctrl          <= s_axi_wdata[1:0];
                    default: ;
                endcase
            end else begin
                // Auto-clear single-cycle control strobe pulses
                reg_ctrl <= 2'b00;
            end

            // Write Response logic
            if (s_axi_awready && s_axi_awvalid && ~s_axi_bvalid && s_axi_wready && s_axi_wvalid) begin
                s_axi_bvalid <= 1'b1;
                s_axi_bresp  <= 2'b00;
            end else if (s_axi_bready && s_axi_bvalid) begin
                s_axi_bvalid <= 1'b0;
                aw_en        <= 1'b1;
            end
        end
    end

    // ==========================================
    // AXI4-Lite Read Channel Handshake & Logic
    // ==========================================
    reg [31:0] axi_araddr_reg;

    always @(posedge s_axi_aclk or negedge s_axi_aresetn) begin
        if (!s_axi_aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 32'h0;
        end else begin
            // Read Address Ready logic
            if (~s_axi_arready && s_axi_arvalid) begin
                s_axi_arready  <= 1'b1;
                axi_araddr_reg <= s_axi_araddr;
            end else begin
                s_axi_arready  <= 1'b0;
            end

            // Read Data Read Logic
            if (s_axi_arready && s_axi_arvalid && ~s_axi_rvalid) begin
                s_axi_rvalid <= 1'b1;
                s_axi_rresp  <= 2'b00;

                case (axi_araddr_reg[7:0])
                    8'h00: s_axi_rdata <= reg_data_in;
                    8'h04: s_axi_rdata <= ecc_codeword_out[31:0];
                    8'h08: s_axi_rdata <= {25'd0, ecc_codeword_out[38:32]};
                    8'h0C: s_axi_rdata <= ecc_data_corrected;
                    8'h10: s_axi_rdata <= {21'd0, no_error_flag, ded_flag, sec_flag, 6'd0, reg_ctrl};
                    default: s_axi_rdata <= 32'hDEADBEEF;
                endcase
            end else if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule