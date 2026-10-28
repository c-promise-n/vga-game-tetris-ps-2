`timescale 1ns / 1ps
module score_display(
input clk,
input rst_n,
input [3:0]hundrens,
input [3:0]tens,
input [3:0]ones,
output [6:0]seg,
output dp,
output [3:0]an
);
wire [3:0]dp_mask;
assign dp_mask=4'b0000;
scan_ctrl u_scan_ctrl (
    .clk    (clk),
    .rst_n  (rst_n),
    .data0  (ones),
    .data1  (tens),
    .data2  (hundrens),
    .data3  (4'b0000),
    .dp_mask(dp_mask),
    .blank  (0),
    .an     (an),
    .seg    (seg),
    .dp     (dp)
);
endmodule
