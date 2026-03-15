// system_verification_tb.v
// Final verification testbench: Loads MNIST weights and performs a 4x4 sub-matrix multiplication.

`timescale 1ns/1ps

module system_verification_tb;

    // Parameters
    localparam CLK_PERIOD = 10;
    localparam ADDR_WIDTH = 32;
    localparam DATA_WIDTH = 32;

    // AXI4-Lite Signals
    reg s_axi_aclk;
    reg s_axi_aresetn;
    reg [ADDR_WIDTH-1:0] s_axi_awaddr;
    reg s_axi_awvalid;
    wire s_axi_awready;
    reg [DATA_WIDTH-1:0] s_axi_wdata;
    reg [3:0] s_axi_wstrb;
    reg s_axi_wvalid;
    wire s_axi_wready;
    wire [1:0] s_axi_bresp;
    wire s_axi_bvalid;
    reg s_axi_bready;
    reg [ADDR_WIDTH-1:0] s_axi_araddr;
    reg s_axi_arvalid;
    wire s_axi_arready;
    wire [DATA_WIDTH-1:0] s_axi_rdata;
    wire [1:0] s_axi_rresp;
    wire s_axi_rvalid;
    reg s_axi_rready;

    // Test Memory for Weights and Inputs
    reg signed [7:0] weight_mem [0:50175]; // layer1 weights
    reg signed [7:0] input_mem  [0:783];   // dummy input

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

    // AXI4-Lite Helper Tasks
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

    integer i, t;
    reg [31:0] read_val;
    reg signed [31:0] expected_sum;

    initial begin
        // Initialize
        s_axi_aresetn = 0;
        s_axi_awvalid = 0;
        s_axi_wvalid = 0;
        s_axi_bready = 0;
        s_axi_arvalid = 0;
        s_axi_rready = 0;

        // Load weights from file
        $readmemh("weights_layer1.mem", weight_mem);

        // Initialize dummy inputs (just use index for variety)
        for (i = 0; i < 784; i = i + 1) begin
            input_mem[i] = (i % 10) - 5; // values in range [-5, 4]
        end

        // Wait for reset to finish
        repeat(10) @(posedge s_axi_aclk);
        s_axi_aresetn = 1;
        repeat(5) @(posedge s_axi_aclk);

        // --- System Verification: Hardware Inference on 4x4 Slice ---
        // A (Inputs) * B (Weights) = Y (Outputs)
        // A is 4x4, B is 4x4
        // PE[i,j] = sum_{t=0..3} A[i, t] * B[t, j]

        // Feed inputs for 4 cycles
        for (t = 0; t < 4; t = t + 1) begin
            // Matrix A inputs: Feed A[i, t] to Row i
            axi_write(32'h00, {24'd0, input_mem[0*4 + t]});
            axi_write(32'h04, {24'd0, input_mem[1*4 + t]});
            axi_write(32'h08, {24'd0, input_mem[2*4 + t]});
            axi_write(32'h0C, {24'd0, input_mem[3*4 + t]});

            // Matrix B inputs: Feed B[t, j] to Col j
            // For FC layer: Output[j] = Sum_t (Input[t] * Weight[j][t])
            // Weight[j][t] is at weight_mem[j*784 + t]
            axi_write(32'h10, {24'd0, weight_mem[0*784 + t]});
            axi_write(32'h14, {24'd0, weight_mem[1*784 + t]});
            axi_write(32'h18, {24'd0, weight_mem[2*784 + t]});
            axi_write(32'h1C, {24'd0, weight_mem[3*784 + t]});

            // Pulse Enable for 1 cycle to shift the data into the array
            axi_write(32'hA0, 32'h1);
        end

        // Clear inputs before flushing to avoid unwanted accumulations
        axi_write(32'h00, 32'd0); axi_write(32'h04, 32'd0); axi_write(32'h08, 32'd0); axi_write(32'h0C, 32'd0);
        axi_write(32'h10, 32'd0); axi_write(32'h14, 32'd0); axi_write(32'h18, 32'd0); axi_write(32'h1C, 32'd0);

        // Pipeline Flush: The systolic array needs cycles to propagate data
        for (t = 0; t < 10; t = t + 1) begin
            axi_write(32'hA0, 32'h1);
        end

        // Wait a few cycles
        repeat(10) @(posedge s_axi_aclk);

        // Read result from PE[0,0]
        axi_read(32'h20, read_val);

        // Calculate expected value: sum(A[0, t] * B[t, 0]) for t=0..3
        expected_sum = 0;
        for (t = 0; t < 4; t = t + 1) begin
            expected_sum = expected_sum + (input_mem[0*4 + t] * weight_mem[0*784 + t]);
        end

        $display("Expected PE[0,0] = %d", expected_sum);
        $display("Actual   PE[0,0] = %d", $signed(read_val));

        if ($signed(read_val) == expected_sum)
            $display("--- SYSTEM VERIFICATION PASSED ---");
        else
            $display("--- SYSTEM VERIFICATION FAILED ---");

        $finish;
    end

endmodule
