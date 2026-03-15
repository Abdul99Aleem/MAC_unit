// systolic_array_4x4_tb.v
// Testbench for 4x4 systolic array with internal skewing and feedback accumulation.

`timescale 1ns/1ps

module systolic_array_4x4_tb;

    reg         clk;
    reg         rst_n;
    reg  [31:0] a_in;
    reg  [31:0] b_in;
    wire [511:0] acc_out;

    // Instantiate the 4x4 Systolic Array
    systolic_array_4x4 uut (
        .clk(clk),
        .rst_n(rst_n),
        .a_in(a_in),
        .b_in(b_in),
        .acc_out(acc_out)
    );

    // Clock generation (10ns period)
    initial clk = 0;
    always #5 clk = ~clk;

    // Helper to get PE output from packed wire
    function signed [31:0] get_pe_acc(input integer row, input integer col);
        get_pe_acc = acc_out[(row*4 + col)*32 +: 32];
    endfunction

    integer i, j;

    // --- Test Data ---
    reg signed [7:0] A_mat [0:3][0:3];
    reg signed [7:0] B_mat [0:3][0:3];
    reg signed [31:0] Expected_C [0:3][0:3];

    initial begin
        // --- Initialization and Reset ---
        rst_n = 0;
        a_in = 32'h0;
        b_in = 32'h0;

        // Initialize Test Matrices
        // A = [1 2 3 4; 1 2 3 4; 1 2 3 4; 1 2 3 4]
        // B = [1 1 1 1; 2 2 2 2; 3 3 3 3; 4 4 4 4]
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                A_mat[i][j] = j + 1;
                B_mat[i][j] = i + 1;
            end
        end

        // Calculate Expected C = A * B
        // C[i][j] = sum(A[i][k] * B[k][j]) = 1*1 + 2*2 + 3*3 + 4*4 = 1+4+9+16 = 30
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                Expected_C[i][j] = 30;
            end
        end

        repeat(2) @(posedge clk);
        #1 rst_n = 1;

        $display("--- Starting Full Matrix Multiplication Test ---");
        $display("Expected result for all PEs: 30");

        // Feed matrices over 4 cycles
        // Cycle 0: A[*,0], B[0,*]
        // Cycle 1: A[*,1], B[1,*]
        // ...
        for (i = 0; i < 4; i = i + 1) begin
            a_in = {A_mat[3][i], A_mat[2][i], A_mat[1][i], A_mat[0][i]};
            b_in = {B_mat[i][3], B_mat[i][2], B_mat[i][1], B_mat[i][0]};
            @(posedge clk); #1;
        end

        a_in = 32'h0;
        b_in = 32'h0;

        // Wait for pipeline to drain (skew + propagation + MAC register)
        // Max delay: 3 (skew) + 3 (propagation) + 1 (MAC) = 7 cycles min, wait 15 to be safe
        repeat(15) @(posedge clk);

        // Verification
        for (i = 0; i < 4; i = i + 1) begin
            for (j = 0; j < 4; j = j + 1) begin
                $display("PE(%0d,%0d) Result: %d", i, j, get_pe_acc(i,j));
                if (get_pe_acc(i,j) !== Expected_C[i][j]) begin
                    $display("FAIL: PE(%0d,%0d) expected %d, got %d", i, j, Expected_C[i][j], get_pe_acc(i,j));
                    $finish;
                end
            end
        end

        $display("--- MATRIX MULTIPLICATION SUCCESS ---");
        $finish;
    end

endmodule
