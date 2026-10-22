`timescale 1ns / 1ps
module cell_map(
input clk,
input rst_n,
input de,
input pixel_ce,
output reg [4:0]col_idx,
output reg [4:0]raw_idx,
output reg [3:0]col_px,
output reg [3:0]raw_px
    );
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
        col_idx=0;
        raw_idx=0;
        col_px=0;
        raw_px=0;
        end else if(de)begin
            if(col_idx == 26)begin
                col_idx=0;
                if(raw_px==11)begin
                    raw_px=0;
                end else
                raw_px=raw_px+1;
            end
            else if(pixel_ce)begin
                if(col_px == 4'd11)begin
                    col_idx=col_idx+1;
                    col_px=0;
                end else begin
                    col_px=col_px+1;
                end
            end
        end
    end
endmodule
