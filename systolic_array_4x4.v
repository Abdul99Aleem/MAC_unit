// systolic_array_4x4.v
// 4x4 systolic array using 8-bit signed MAC units
// Implements internal skewing and local accumulation feedback.

`timescale 1ns/1ps

module systolic_array_4x4 (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,       // Added enable
    input  wire [31:0] a_in,    // 4 rows * 8 bits
    input  wire [31:0] b_in,    // 4 cols * 8 bits
    output wire [511:0] acc_out // 16 PEs * 32 bits
);

    // --- Internal Skewing Registers ---

    // Row Skewing (A inputs)
    reg signed [7:0] a_row0_delay0;

    reg signed [7:0] a_row1_delay0;
    reg signed [7:0] a_row1_delay1;

    reg signed [7:0] a_row2_delay0;
    reg signed [7:0] a_row2_delay1;
    reg signed [7:0] a_row2_delay2;

    reg signed [7:0] a_row3_delay0;
    reg signed [7:0] a_row3_delay1;
    reg signed [7:0] a_row3_delay2;
    reg signed [7:0] a_row3_delay3;

    // Column Skewing (B inputs)
    reg signed [7:0] b_col0_delay0;

    reg signed [7:0] b_col1_delay0;
    reg signed [7:0] b_col1_delay1;

    reg signed [7:0] b_col2_delay0;
    reg signed [7:0] b_col2_delay1;
    reg signed [7:0] b_col2_delay2;

    reg signed [7:0] b_col3_delay0;
    reg signed [7:0] b_col3_delay1;
    reg signed [7:0] b_col3_delay2;
    reg signed [7:0] b_col3_delay3;

    always @(posedge clk) begin
        if (!rst_n) begin
            a_row0_delay0 <= 8'sd0;
            a_row1_delay0 <= 8'sd0; a_row1_delay1 <= 8'sd0;
            a_row2_delay0 <= 8'sd0; a_row2_delay1 <= 8'sd0; a_row2_delay2 <= 8'sd0;
            a_row3_delay0 <= 8'sd0; a_row3_delay1 <= 8'sd0; a_row3_delay2 <= 8'sd0; a_row3_delay3 <= 8'sd0;

            b_col0_delay0 <= 8'sd0;
            b_col1_delay0 <= 8'sd0; b_col1_delay1 <= 8'sd0;
            b_col2_delay0 <= 8'sd0; b_col2_delay1 <= 8'sd0; b_col2_delay2 <= 8'sd0;
            b_col3_delay0 <= 8'sd0; b_col3_delay1 <= 8'sd0; b_col3_delay2 <= 8'sd0; b_col3_delay3 <= 8'sd0;
        end else if (en) begin
            // Row Skewing
            a_row0_delay0 <= a_in[7:0];

            a_row1_delay0 <= a_in[15:8];
            a_row1_delay1 <= a_row1_delay0;

            a_row2_delay0 <= a_in[23:16];
            a_row2_delay1 <= a_row2_delay0;
            a_row2_delay2 <= a_row2_delay1;

            a_row3_delay0 <= a_in[31:24];
            a_row3_delay1 <= a_row3_delay0;
            a_row3_delay2 <= a_row3_delay1;
            a_row3_delay3 <= a_row3_delay2;

            // Col Skewing
            b_col0_delay0 <= b_in[7:0];

            b_col1_delay0 <= b_in[15:8];
            b_col1_delay1 <= b_col1_delay0;

            b_col2_delay0 <= b_in[23:16];
            b_col2_delay1 <= b_col2_delay0;
            b_col2_delay2 <= b_col2_delay1;

            b_col3_delay0 <= b_in[31:24];
            b_col3_delay1 <= b_col3_delay0;
            b_col3_delay2 <= b_col3_delay1;
            b_col3_delay3 <= b_col3_delay2;
        end
    end

    // --- Propagation Wires and Registers ---

    // a_pipe[row][col] is the 'a' signal entering PE(row, col)
    wire signed [7:0] a_pipe [0:3][0:3];
    // b_pipe[row][col] is the 'b' signal entering PE(row, col)
    wire signed [7:0] b_pipe [0:3][0:3];

    // a_reg[row][col] is the 'a' signal leaving PE(row, col) after 1 cycle
    reg signed [7:0] a_reg [0:3][0:3];
    // b_reg[row][col] is the 'b' signal leaving PE(row, col) after 1 cycle
    reg signed [7:0] b_reg [0:3][0:3];

    // Connect Initial Inputs to a_pipe/b_pipe
    assign a_pipe[0][0] = a_row0_delay0;
    assign a_pipe[1][0] = a_row1_delay1;
    assign a_pipe[2][0] = a_row2_delay2;
    assign a_pipe[3][0] = a_row3_delay3;

    assign b_pipe[0][0] = b_col0_delay0;
    assign b_pipe[0][1] = b_col1_delay1;
    assign b_pipe[0][2] = b_col2_delay2;
    assign b_pipe[0][3] = b_col3_delay3;

    // Propagation logic
    integer r, c;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    a_reg[r][c] <= 8'sd0;
                    b_reg[r][c] <= 8'sd0;
                end
            end
        end else if (en) begin
            for (r = 0; r < 4; r = r + 1) begin
                for (c = 0; c < 4; c = c + 1) begin
                    a_reg[r][c] <= a_pipe[r][c];
                    b_reg[r][c] <= b_pipe[r][c];
                end
            end
        end
    end

    // Connect pipes between PEs
    generate
        genvar i, j;
        for (i = 0; i < 4; i = i + 1) begin : gen_row
            for (j = 1; j < 4; j = j + 1) begin : gen_col_a
                assign a_pipe[i][j] = a_reg[i][j-1];
            end
        end
        for (j = 0; j < 4; j = j + 1) begin : gen_col
            for (i = 1; i < 4; i = i + 1) begin : gen_row_b
                assign b_pipe[i][j] = b_reg[i-1][j];
            end
        end
    endgenerate

    // --- PE Grid Instantiation ---
    wire signed [31:0] pe_acc_out [0:3][0:3];

    generate
        genvar gi, gj;
        for (gi = 0; gi < 4; gi = gi + 1) begin : row_pe
            for (gj = 0; gj < 4; gj = gj + 1) begin : col_pe
                mac_unit pe (
                    .clk(clk),
                    .rst_n(rst_n),
                    .en(en),
                    .a(a_pipe[gi][gj]),
                    .b(b_pipe[gi][gj]),
                    .acc_in(pe_acc_out[gi][gj]), // Feedback
                    .acc_out(pe_acc_out[gi][gj])
                );

                // Pack into final output vector
                assign acc_out[(gi*4 + gj)*32 +: 32] = pe_acc_out[gi][gj];
            end
        end
    endgenerate

endmodule
