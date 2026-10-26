`timescale 1ns / 1ps
module btn_sync(
input clk,
input rst_n,
input btn_l,btn_r,btn_u,btn_d,btn_c,
input sw_pause,sw_restart,
output [7:0]btn_pressed
    );

    wire lv_l,lv_r,lv_u,lv_d,lv_c,lv_pause,lv_restart;

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

    debounce #(
        .CNT_MAX(2_000_000)
    ) btn_c_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy_in (btn_c),
        .clean_out(lv_c)
    );
    debounce #(
        .CNT_MAX(2_000_000)
    ) sw_pause_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy_in (sw_pause),
        .clean_out(lv_pause)
    );
    debounce #(
        .CNT_MAX(2_000_000)
    ) sw_restart_debounce (
        .clk      (clk),
        .rst_n    (rst_n),
        .noisy_in (sw_restart),
        .clean_out(lv_restart)
    );
    //bit6=RESTART,bit_5=PAUSE,bit4=DROP,bit3=ROTATE,bit2=DOWN,bit1=RIGHT,bit0=LEFT
    assign btn_pressed={1'b0,lv_restart,lv_pause,lv_c,lv_u,lv_d,lv_r,lv_l};
endmodule
