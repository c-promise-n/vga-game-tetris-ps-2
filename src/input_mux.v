`timescale 1ns / 1ps
module input_mux(
input clk,
input rst_n,
input [7:0]kb_key_pressed,
input [7:0]btn_key_pressed,
output [7:0]key_pressed,
output [7:0]key_edge
    );
    assign key_pressed=kb_key_pressed|btn_key_pressed;
    reg [7:0]pressed_d;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            pressed_d<=8'b0;
        end else begin
            pressed_d<=key_pressed;
        end
    end
    assign key_edge = key_pressed&(~pressed_d);
endmodule
