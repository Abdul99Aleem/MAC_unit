// mac_unit.v
// 8-bit signed multiply-accumulate unit for 4x4 systolic array
// Target: Xilinx Zynq FPGA (infers DSP48 slice)

`timescale 1ns/1ps

module mac_unit (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        en,
    input  wire signed [7:0]  a,
    input  wire signed [7:0]  b,
    input  wire signed [31:0] acc_in,
    output reg  signed [31:0] acc_out
);

    (* use_dsp = "yes" *)
    always @(posedge clk) begin
        if (!rst_n)
            acc_out <= 32'sd0;
        else if (en)
            acc_out <= acc_in + (a * b);
    end

endmodule
