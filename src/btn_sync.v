`timescale 1ns / 1ps
module btn_sync(
input clk,
input rst_n,
input btn_l,btn_r,btn_u,btn_d,
output [7:0]btn_pressed
    );

    wire lv_l,lv_r,lv_u,lv_d;
    debounce #(
        .CNT_MAX(2_000_000)
    ) btn_l_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy_in (btn_l),
        .clean_out(lv_l)
    );

    debounce #(
        .CNT_MAX(2_000_000)
    ) btn_r_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy_in (btn_r),
        .clean_out(lv_r)
    );

    debounce #(
        .CNT_MAX(2_000_000)
    ) btn_u_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy_in (btn_u),
        .clean_out(lv_u)
    );

    debounce #(
        .CNT_MAX(2_000_000)
    ) btn_d_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy_in (btn_d),
        .clean_out(lv_d)
    );

    //bit3=ROTATE,bit2=DOWN,bit1=RIGHT,bit0=LEFT
    assign btn_pressed={4'b0000,lv_u,lv_d,lv_r,lv_l};
endmodule
