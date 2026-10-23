`timescale 1ns / 1ps
module key_state(
input clk,
input rst_n,
input [2:0]key_id,
input key_down,
input key_hit,

output reg [7:0]key_pressed,
output reg [7:0]key_edge
    );

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            key_pressed<=8'b0;
            key_edge<=3'b0;
        end else begin
            key_edge<=1'b0;
            if(key_hit)begin
            if(key_down)begin
                if(!key_pressed[key_id])begin
                    key_edge<=1'b1;
                end
                key_pressed[key_id]<=1'b1;
            end else begin
                key_pressed[key_id]<=1'b0;
            end
            end
        end
    end
endmodule
