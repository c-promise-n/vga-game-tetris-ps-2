`timescale 1ns / 1ps
module vga_timing(
    input clk,
    input rst_n,

    output de,//data enable
    output pixel_ce,

    output [9:0]px,
    output [9:0]py,
    output hsync,//active low
    output vsync//active low
    );
    parameter hsync_end = 10'd95,
        hdat_begin = 10'd144,
        hdat_end = 10'd784,
        hpixel_end = 10'd799,

        vsync_end = 10'd1,
        vdat_begin = 10'd35,
        vdat_end = 10'd515,
        vline_end = 10'd524;
    reg [1:0]cnt;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <=  2'b0;
        end else begin
            cnt <=  cnt+1'b1;
        end
    end
    assign pixel_ce=(cnt == 2'd3);

    reg [9:0]hcount,vcount;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            hcount <= 10'b0;
        end else if(pixel_ce) begin
            if(hcount==hpixel_end)begin
                hcount <=   0;
            end else begin
                hcount <=   hcount + 1'b1;
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
             vcount <=10'b0;
        end else if(pixel_ce)begin
            if(hcount==hpixel_end)begin
                if(vcount==vline_end)begin
                    vcount <=   0;
                end else begin
                    vcount <=   vcount + 1'b1;
                end
            end
        end
    end
assign hsync= (hcount > hsync_end);
assign vsync= (vcount > vsync_end);
assign de=  (hcount>= hdat_begin)&&(hcount < hdat_end)&&(vcount>= vdat_begin)&&(vcount < vdat_end);
assign px=de?( hcount - hdat_begin):10'd0;
assign py= vcount - vdat_begin;
endmodule
