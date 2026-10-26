`timescale 1ns / 1ps
module input_subsystem(
input clk,
input rst_n,
input btn_l,btn_r,btn_u,btn_d,btn_c,
input sw_pause,sw_restart,
input frame_tick,

output [7:0]key_pressed,
output [7:0]key_edge,
output  move_right,move_left
    );

    wire [7:0] level;
    btn_sync btn_sync (
        .clk        (clk),
        .rst_n      (rst_n),
        .btn_l      (btn_l),
        .btn_r      (btn_r),
        .btn_u      (btn_u),
        .btn_d      (btn_d),
        .btn_c      (btn_c),
        .sw_pause   (sw_pause),
        .sw_restart (sw_restart),
        .btn_pressed(level)
    );

    reg[7:0]level_d;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) level_d<=8'b0;
        else level_d<=level;
    end

    assign key_pressed=level;
    assign key_edge=level &(~level_d);

    key_repeat #(
        .DAS(9),
        .ARR(3)
     ) u_l (
        .clk        (clk),
        .rst_n      (rst_n),
        .frame_tick (frame_tick),
        .key_pressed(level[0]),
        .pulse      (move_left)
    );

    key_repeat #(
        .DAS(9),
        .ARR(3)
     ) key_repeat (
        .clk        (clk),
        .rst_n      (rst_n),
        .frame_tick (frame_tick),
        .key_pressed(level[1]),
        .pulse      (move_right)
    );
endmodule
