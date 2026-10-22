`timescale 1ns / 1ps
module pixel_pipe(
input clk,
input rst_n,
input hsync_i,
input vsync_i,
input reg [11:0]rgb_i,
output reg hsync_o,
output reg vsync_o,
output reg [11:0]rgb_o
    );

always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
        hsync_o<=1'b0;
        vsync_o<=1'b0;
        rgb_o<=12'b0;
    end else begin
        hsync_o<=hsync_i;
        vsync_o<=vsync_i;
        rgb_o<=rgb_i;
    end
end

endmodule
