// mac_unit_tb.v
// Self-checking testbench for mac_unit
// Tests: pos*pos, neg*pos, neg*neg, zero, accumulation

`timescale 1ns/1ps

module mac_unit_tb;

    // DUT signals
    reg        clk;
    reg        rst_n;
    reg  signed [7:0]  a;
    reg  signed [7:0]  b;
    reg  signed [31:0] acc_in;
    wire signed [31:0] acc_out;

    // Instantiate DUT
    mac_unit uut (
        .clk    (clk),
        .rst_n  (rst_n),
        .a      (a),
        .b      (b),
        .acc_in (acc_in),
        .acc_out(acc_out)
    );

    // 10 ns clock period
    initial clk = 0;
    always #5 clk = ~clk;

    // Test infrastructure
    integer pass_count = 0;
    integer fail_count = 0;

    task check;
        input [127:0] name;   // test name (padded string)
        input signed [31:0] expected;
        begin
            // acc_out is registered, so it reflects the previous cycle's inputs
            if (acc_out === expected) begin
                $display("PASS | %0s | expected=%0d, got=%0d", name, expected, acc_out);
                pass_count = pass_count + 1;
            end else begin
                $display("FAIL | %0s | expected=%0d, got=%0d", name, expected, acc_out);
                fail_count = fail_count + 1;
            end
        end
    endtask

    integer i;

    initial begin
        // ── Reset ──────────────────────────────────────────
        rst_n  = 0;
        a      = 8'sd0;
        b      = 8'sd0;
        acc_in = 32'sd0;
        @(posedge clk); #1;
        @(posedge clk); #1;
        rst_n = 1;

        // ── Test 1: positive * positive ────────────────────
        // a=5, b=6, acc_in=0  →  expected = 0 + 5*6 = 30
        a      = 8'sd5;
        b      = 8'sd6;
        acc_in = 32'sd0;
        @(posedge clk); #1;
        check("pos*pos        ", 32'sd30);

        // ── Test 2: negative * positive ────────────────────
        // a=-4, b=7, acc_in=0  →  expected = 0 + (-4)*7 = -28
        a      = -8'sd4;
        b      =  8'sd7;
        acc_in = 32'sd0;
        @(posedge clk); #1;
        check("neg*pos        ", -32'sd28);

        // ── Test 3: negative * negative ────────────────────
        // a=-3, b=-8, acc_in=0  →  expected = 0 + (-3)*(-8) = 24
        a      = -8'sd3;
        b      = -8'sd8;
        acc_in = 32'sd0;
        @(posedge clk); #1;
        check("neg*neg        ", 32'sd24);

        // ── Test 4: zero input ─────────────────────────────
        // a=0, b=127, acc_in=100  →  expected = 100 + 0*127 = 100
        a      = 8'sd0;
        b      = 8'sd127;
        acc_in = 32'sd100;
        @(posedge clk); #1;
        check("zero*anything  ", 32'sd100);

        // ── Test 5: accumulation across cycles ─────────────
        // Cycle A: a=2, b=3, acc_in=0   → acc_out = 6
        // Cycle B: a=4, b=5, acc_in=6   → acc_out = 26
        // Cycle C: a=1, b=1, acc_in=26  → acc_out = 27
        a      = 8'sd2;
        b      = 8'sd3;
        acc_in = 32'sd0;
        @(posedge clk); #1;
        // acc_out = 6 now; feed it back
        a      = 8'sd4;
        b      = 8'sd5;
        acc_in = acc_out;          // = 6
        @(posedge clk); #1;
        // acc_out = 26 now; feed it back
        a      = 8'sd1;
        b      = 8'sd1;
        acc_in = acc_out;          // = 26
        @(posedge clk); #1;
        check("accumulation   ", 32'sd27);

        // ── Summary ────────────────────────────────────────
        $display("------------------------------------------");
        $display("Results: %0d PASSED, %0d FAILED", pass_count, fail_count);
        $display("------------------------------------------");
        $finish;
    end

endmodule
