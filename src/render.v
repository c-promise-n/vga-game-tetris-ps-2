`timescale 1ns / 1ps
module render(
input [8:0]px_log,
input [8:0]py_log,
input rst_n,
input hit_piece,
input occ,
input grid,
input [2:0]p_type,
output reg[3:0]color_idx
    );

    localparam well_end  = 119,
               panel_begin=132;

    always @(*) begin
        if(!rst_n)begin
            color_idx   = 4'h0;
        end else if(px_log <= well_end)begin
            if(hit_piece)begin
                color_idx = p_type +4'h2;
            end else if(occ)begin
                color_idx = p_type + 4'h2;
            end else if(grid)begin
                color_idx= 4'h1;
            end else begin
                color_idx= 4'hE;
            end
        end else if(px_log < panel_begin)begin
            color_idx=  4'h0;
        end else begin
            color_idx=4'h0;
        end
    end
endmodule
