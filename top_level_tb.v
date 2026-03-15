// top_level_tb.v
// Testbench for top-level AXI4-Lite wrapper for 4x4 systolic array

`timescale 1ns/1ps

module top_level_tb;

    // Parameters
    localparam CLK_PERIOD = 10;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;

    // Signals
    reg s_axi_aclk;
    reg s_axi_aresetn;

    // Write Address Channel
    reg [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg s_axi_awvalid;
    wire s_axi_awready;

    // Write Data Channel
    reg [DATA_WIDTH-1:0] s_axi_wdata;
    reg [3:0] s_axi_wstrb;
    reg s_axi_wvalid;
    wire s_axi_wready;

    // Write Response Channel
    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_bready;

    // Read Address Channel
    reg [ADDR_WIDTH-1:0] s_axi_araddr;
    reg s_axi_arvalid;
    wire s_axi_arready;

    // Read Data Channel
    wire [DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    reg s_axi_rready;

    // Instantiate DUT
    top_level dut (
        .s_axi_aclk(s_axi_aclk),
        .s_axi_aresetn(s_axi_aresetn),
        .s_axi_awaddr(s_axi_awaddr),
        .s_axi_awvalid(s_axi_awvalid),
        .s_axi_awready(s_axi_awready),
        .s_axi_wdata(s_axi_wdata),
        .s_axi_wstrb(s_axi_wstrb),
        .s_axi_wvalid(s_axi_wvalid),
        .s_axi_wready(s_axi_wready),
        .s_axi_bresp(s_axi_bresp),
        .s_axi_bvalid(s_axi_bvalid),
        .s_axi_bready(s_axi_bready),
        .s_axi_araddr(s_axi_araddr),
        .s_axi_arvalid(s_axi_arvalid),
        .s_axi_arready(s_axi_arready),
        .s_axi_rdata(s_axi_rdata),
        .s_axi_rresp(s_axi_rresp),
        .s_axi_rvalid(s_axi_rvalid),
        .s_axi_rready(s_axi_rready)
    );

    // Clock Generation
    initial begin
        s_axi_aclk = 0;
        forever #(CLK_PERIOD/2) s_axi_aclk = ~s_axi_aclk;
    end

    // AXI4-Lite Write Task
    task axi_write(input [ADDR_WIDTH-1:0] addr, input [DATA_WIDTH-1:0] data);
    begin
        @(posedge s_axi_aclk);
        s_axi_awaddr <= addr;
        s_axi_awvalid <= 1;
        s_axi_wdata <= data;
        s_axi_wstrb <= 4'hF;
        s_axi_wvalid <= 1;
        s_axi_bready <= 1;

        wait(s_axi_awready && s_axi_wready);
        @(posedge s_axi_aclk);
        s_axi_awvalid <= 0;
        s_axi_wvalid <= 0;

        wait(s_axi_bvalid);
        @(posedge s_axi_aclk);
        s_axi_bready <= 0;
    end
    endtask

    // AXI4-Lite Read Task
    task axi_read(input [ADDR_WIDTH-1:0] addr, output [DATA_WIDTH-1:0] data);
    begin
        @(posedge s_axi_aclk);
        s_axi_araddr <= addr;
        s_axi_arvalid <= 1;
        s_axi_rready <= 1;

        wait(s_axi_arready);
        @(posedge s_axi_aclk);
        s_axi_arvalid <= 0;

        wait(s_axi_rvalid);
        data = s_axi_rdata;
        @(posedge s_axi_aclk);
        s_axi_rready <= 0;
    end
    endtask

    integer i;
    reg [31:0] read_val;

    // Main Test Sequence
    initial begin
        // Reset
        s_axi_aresetn = 0;
        s_axi_awaddr = 0;
        s_axi_awvalid = 0;
        s_axi_wdata = 0;
        s_axi_wstrb = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_araddr = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        repeat(5) @(posedge s_axi_aclk);
        s_axi_aresetn = 1;
        repeat(5) @(posedge s_axi_aclk);

        $display("--- Starting AXI4-Lite Systolic Array Test ---");

        // 1. Write to a_in[0..3] (0x00, 0x04, 0x08, 0x0C)
        for (i = 0; i < 4; i = i + 1) begin
            axi_write(32'h00 + (i*4), i + 1); // 1, 2, 3, 4
        end

        // 2. Write to b_in[0..3] (0x10, 0x14, 0x18, 0x1C)
        for (i = 0; i < 4; i = i + 1) begin
            axi_write(32'h10 + (i*4), (i + 1) * 10); // 10, 20, 30, 40
        end

        // 3. Write to Control/Status (0xA0) - Enable
        axi_write(32'hA0, 32'h1);

        // 4. Wait for some cycles for systolic computation to progress
        repeat(20) @(posedge s_axi_aclk);

        // 5. Read back acc_out[0..15] (0x20..0x5C)
        for (i = 0; i < 16; i = i + 1) begin
            axi_read(32'h20 + (i*4), read_val);
            $display("Read acc_out[%0d] = %d", i, $signed(read_val));
        end

        // Basic verification (PE[0,0] should have accumulated something)
        // Since we are feeding continuous 1 * 10 after enable, it should be > 0
        axi_read(32'h20, read_val);
        if ($signed(read_val) > 0)
            $display("TEST PASSED: PE[0,0] accumulated value %d", $signed(read_val));
        else
            $display("TEST FAILED: PE[0,0] value %d", $signed(read_val));

        $finish;
    end

endmodule
