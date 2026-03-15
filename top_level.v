// top_level.v
// AXI4-Lite top-level wrapper for 4x4 systolic array

`timescale 1ns/1ps

module top_level # (
    parameter integer C_S_AXI_DATA_WIDTH = 32,
    parameter integer C_S_AXI_ADDR_WIDTH = 32
)(
    // AXI4-Lite Slave Interface
    input  wire                                 s_axi_aclk,
    input  wire                                 s_axi_aresetn,

    // Write Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]        s_axi_awaddr,
    input  wire                                 s_axi_awvalid,
    output wire                                 s_axi_awready,

    // Write Data Channel
    input  wire [C_S_AXI_DATA_WIDTH-1:0]        s_axi_wdata,
    input  wire [(C_S_AXI_DATA_WIDTH/8)-1:0]    s_axi_wstrb,
    input  wire                                 s_axi_wvalid,
    output wire                                 s_axi_wready,

    // Write Response Channel
    output wire [1:0]                           s_axi_bresp,
    output wire                                 s_axi_bvalid,
    input  wire                                 s_axi_bready,

    // Read Address Channel
    input  wire [C_S_AXI_ADDR_WIDTH-1:0]        s_axi_araddr,
    input  wire                                 s_axi_arvalid,
    output wire                                 s_axi_arready,

    // Read Data Channel
    output wire [C_S_AXI_DATA_WIDTH-1:0]        s_axi_rdata,
    output wire [1:0]                           s_axi_rresp,
    output wire                                 s_axi_rvalid,
    input  wire                                 s_axi_rready
);

    // Register Map Offsets
    localparam ADDR_A_IN_BASE  = 8'h00; // 0x00-0x0C (4 regs)
    localparam ADDR_B_IN_BASE  = 8'h10; // 0x10-0x1C (4 regs)
    localparam ADDR_ACC_BASE   = 8'h20; // 0x20-0x5C (16 regs)
    localparam ADDR_CONTROL    = 8'hA0; // 0xA0

    // Internal Registers
    reg [7:0] a_regs [0:3];
    reg [7:0] b_regs [0:3];
    reg       control_reg_en;

    // AXI signals
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_awaddr;
    reg                          axi_awready;
    reg                          axi_wready;
    reg [1:0]                    axi_bresp;
    reg                          axi_bvalid;
    reg [C_S_AXI_ADDR_WIDTH-1:0] axi_araddr;
    reg                          axi_arready;
    reg [C_S_AXI_DATA_WIDTH-1:0] axi_rdata;
    reg [1:0]                    axi_rresp;
    reg                          axi_rvalid;

    // Connect AXI outputs
    assign s_axi_awready = axi_awready;
    assign s_axi_wready  = axi_wready;
    assign s_axi_bresp   = axi_bresp;
    assign s_axi_bvalid  = axi_bvalid;
    assign s_axi_arready = axi_arready;
    assign s_axi_rdata   = axi_rdata;
    assign s_axi_rresp   = axi_rresp;
    assign s_axi_rvalid  = axi_rvalid;

    // --- Write Logic ---
    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_awready <= 1'b0;
            axi_wready  <= 1'b0;
            axi_bvalid  <= 1'b0;
            axi_awaddr  <= 0;
            control_reg_en <= 1'b0;
            a_regs[0] <= 8'd0; a_regs[1] <= 8'd0; a_regs[2] <= 8'd0; a_regs[3] <= 8'd0;
            b_regs[0] <= 8'd0; b_regs[1] <= 8'd0; b_regs[2] <= 8'd0; b_regs[3] <= 8'd0;
        end else begin
            // Address Ready
            if (!axi_awready && s_axi_awvalid && s_axi_wvalid) begin
                axi_awready <= 1'b1;
                axi_awaddr  <= s_axi_awaddr;
            end else begin
                axi_awready <= 1'b0;
            end

            // Data Ready
            if (!axi_wready && s_axi_awvalid && s_axi_wvalid) begin
                axi_wready <= 1'b1;
            end else begin
                axi_wready <= 1'b0;
            end

            // Write Data
            if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid) begin
                case (axi_awaddr[7:0])
                    8'h00: a_regs[0] <= s_axi_wdata[7:0];
                    8'h04: a_regs[1] <= s_axi_wdata[7:0];
                    8'h08: a_regs[2] <= s_axi_wdata[7:0];
                    8'h0C: a_regs[3] <= s_axi_wdata[7:0];
                    8'h10: b_regs[0] <= s_axi_wdata[7:0];
                    8'h14: b_regs[1] <= s_axi_wdata[7:0];
                    8'h18: b_regs[2] <= s_axi_wdata[7:0];
                    8'h1C: b_regs[3] <= s_axi_wdata[7:0];
                    8'hA0: control_reg_en <= s_axi_wdata[0];
                    default: ;
                endcase
            end

            // Response
            if (axi_awready && s_axi_awvalid && axi_wready && s_axi_wvalid && !axi_bvalid) begin
                axi_bvalid <= 1'b1;
                axi_bresp  <= 2'b00; // OKAY
            end else if (s_axi_bready && axi_bvalid) begin
                axi_bvalid <= 1'b0;
            end
        end
    end

    // --- Read Logic ---
    wire [511:0] sa_acc_out;

    always @(posedge s_axi_aclk) begin
        if (!s_axi_aresetn) begin
            axi_arready <= 1'b0;
            axi_rvalid  <= 1'b0;
            axi_araddr  <= 0;
            axi_rdata   <= 0;
        end else begin
            // Address Ready
            if (!axi_arready && s_axi_arvalid) begin
                axi_arready <= 1'b1;
                axi_araddr  <= s_axi_araddr;
            end else begin
                axi_arready <= 1'b0;
            end

            // Read Data & Valid
            if (axi_arready && s_axi_arvalid && !axi_rvalid) begin
                axi_rvalid <= 1'b1;
                axi_rresp  <= 2'b00; // OKAY

                // Address decoding
                if (axi_araddr[7:0] >= ADDR_ACC_BASE && axi_araddr[7:0] <= 8'h5C) begin
                    // 0x20 -> index 0, 0x24 -> index 1, etc.
                    axi_rdata <= sa_acc_out[((axi_araddr[7:0] - ADDR_ACC_BASE)/4)*32 +: 32];
                end else begin
                    case (axi_araddr[7:0])
                        8'h00: axi_rdata <= {24'd0, a_regs[0]};
                        8'h04: axi_rdata <= {24'd0, a_regs[1]};
                        8'h08: axi_rdata <= {24'd0, a_regs[2]};
                        8'h0C: axi_rdata <= {24'd0, a_regs[3]};
                        8'h10: axi_rdata <= {24'd0, b_regs[0]};
                        8'h14: axi_rdata <= {24'd0, b_regs[1]};
                        8'h18: axi_rdata <= {24'd0, b_regs[2]};
                        8'h1C: axi_rdata <= {24'd0, b_regs[3]};
                        8'hA0: axi_rdata <= {30'd0, 1'b1, control_reg_en}; // Done bit always 1 for now
                        default: axi_rdata <= 32'd0;
                    endcase
                end
            end else if (axi_rvalid && s_axi_rready) begin
                axi_rvalid <= 1'b0;
            end
        end
    end

    // --- Systolic Array Instance ---
    wire [31:0] sa_a_in = {a_regs[3], a_regs[2], a_regs[1], a_regs[0]};
    wire [31:0] sa_b_in = {b_regs[3], b_regs[2], b_regs[1], b_regs[0]};

    systolic_array_4x4 sa_inst (
        .clk(s_axi_aclk),
        .rst_n(s_axi_aresetn && control_reg_en), // Only run when enabled
        .a_in(sa_a_in),
        .b_in(sa_b_in),
        .acc_out(sa_acc_out)
    );

endmodule
