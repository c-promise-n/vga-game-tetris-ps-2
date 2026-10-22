`timescale 1ns / 1ps
module cell_map(
input clk,
input rst_n,
input de,
input pixel_ce,
input [9:0]px,
input [9:0]py,
output reg [4:0]col_idx,
output reg [4:0]row_idx,
output reg [3:0]col_px,
output reg [3:0]row_px
    );
    wire line_start,frame_start;
    assign line_start=(px==10'b0);
    assign frame_start=(py==10'b0);
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            col_idx<=5'd0;
            row_idx<=5'd0;
            col_px<=4'd0;
            row_px<=4'd0;
        end else if(pixel_ce && de)begin

            if(line_start)begin
                col_px<=4'd0;
                col_idx<=5'd0;
            end else if(px[0]==1'b0)begin
                if(col_px==4'd11)begin
                    col_px<=4'd0;
                    col_idx<=(col_idx==5'd26)?(5'd0):(col_idx+1);
                end else begin
                col_px<=col_px+1'b1;
                end
            end

            if(frame_start)begin
                row_idx<=4'd0;
                row_px<=5'd0;
            end else if(py[0]==1'b0)begin
                if(row_px==11)begin
                    row_px<=4'd0;
                    row_idx<=(row_idx==5'd19)?(5'd0):(row_idx+1);
                end else begin
                    row_px<=row_px+1'b1;
                end
            end
        
        end
    end
endmodule
