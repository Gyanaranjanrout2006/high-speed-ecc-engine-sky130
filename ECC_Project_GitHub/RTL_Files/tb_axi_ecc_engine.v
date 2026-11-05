`timescale 1ns / 1ps

module tb_axi_ecc_engine;
    reg         aclk;
    reg         aresetn;

    // AXI Master Signals
    reg  [31:0] awaddr;
    reg         awvalid;
    wire        awready;
    reg  [31:0] wdata;
    reg  [3:0]  wstrb;
    reg         wvalid;
    wire        wready;
    wire [1:0]  bresp;
    wire        bvalid;
    reg         bready;

    reg  [31:0] araddr;
    reg         arvalid;
    wire        arready;
    wire [31:0] rdata;
    wire [1:0]  rresp;
    wire        rvalid;
    reg         rready;

    // Instantiate AXI Wrapper
    axi_ecc_engine uut (
        .s_axi_aclk    (aclk),
        .s_axi_aresetn (aresetn),
        .s_axi_awaddr  (awaddr),
        .s_axi_awprot  (3'b000),
        .s_axi_awvalid (awvalid),
        .s_axi_awready (awready),
        .s_axi_wdata   (wdata),
        .s_axi_wstrb   (wstrb),
        .s_axi_wvalid  (wvalid),
        .s_axi_wready  (wready),
        .s_axi_bresp   (bresp),
        .s_axi_bvalid  (bvalid),
        .s_axi_bready  (bready),
        .s_axi_araddr  (araddr),
        .s_axi_arprot  (3'b000),
        .s_axi_arvalid (arvalid),
        .s_axi_arready (arready),
        .s_axi_rdata   (rdata),
        .s_axi_rresp   (rresp),
        .s_axi_rvalid  (rvalid),
        .s_axi_rready  (rready)
    );

    always #5 aclk = ~aclk;

    // Master Write Task
    task axi_write(input [31:0] addr, input [31:0] data);
    begin
        @(posedge aclk);
        awaddr  <= addr;
        awvalid <= 1;
        wdata   <= data;
        wstrb   <= 4'b1111;
        wvalid  <= 1;
        bready  <= 1;

        wait (awready && wready);
        @(posedge aclk);
        awvalid <= 0;
        wvalid  <= 0;

        wait (bvalid);
        @(posedge aclk);
        bready  <= 0;
    end
    endtask

    // Master Read Task
    task axi_read(input [31:0] addr);
    begin
        @(posedge aclk);
        araddr  <= addr;
        arvalid <= 1;
        rready  <= 1;

        wait (arready);
        @(posedge aclk);
        arvalid <= 0;

        wait (rvalid);
        @(posedge aclk);
        rready  <= 0;
    end
    endtask

    initial begin
        aclk    = 0;
        aresetn = 0;
        awaddr  = 0;
        awvalid = 0;
        wdata   = 0;
        wstrb   = 0;
        wvalid  = 0;
        bready  = 0;
        araddr  = 0;
        arvalid = 0;
        rready  = 0;

        #30;
        aresetn = 1;
        #20;

        // Step 1: Write Data (32'hDEADBEEF) to REG_DATA_IN (0x00)
        axi_write(32'h00, 32'h12345678);

        // Step 2: Trigger Encode (REG_STATUS_CTRL 0x10 -> bit 0 = 1)
        axi_write(32'h10, 32'h01);

        // Step 3: Read back encoded codeword low (0x04) and high (0x08)
        axi_read(32'h04);
        axi_read(32'h08);

        // Step 4: Inject 1-bit error into codeword and write to Decode registers
        axi_write(32'h04, 32'h12345678 ^ 32'h04); // Corrupt bit 2
        axi_write(32'h08, 32'h6F);

        // Step 5: Trigger Decode (REG_STATUS_CTRL 0x10 -> bit 1 = 1)
        axi_write(32'h10, 32'h02);

        // Step 6: Read Corrected Data (0x0C) and Status Register (0x10)
        axi_read(32'h0C);
        axi_read(32'h10);

        #50;
        $finish;
    end
endmodule