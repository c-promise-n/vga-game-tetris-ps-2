`timescale 1ns / 1ps
module ps2_decoder(
input [7:0]scan_code,
input byte_valid,
input clk,
input rst_n,
output reg [7:0]code,
output reg is_break,
output reg is_ext,
output reg code_valid
    );

    reg ext,brk;
    reg [2:0]pause_cnt;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            ext<=1'b0;
            brk<=1'b0;
            code_valid<=1'b0;
            code<=8'b0;
            is_break<=1'b0;
            is_ext<=1'b0;
            pause_cnt<=3'b0;
        end else begin
            code_valid<=1'b0;
            if(byte_valid)begin
                if(pause_cnt!=3'b0)begin
                    pause_cnt<=pause_cnt-1'b1;
                end else if(scan_code==8'hE0) begin
                    ext<=1'b1;
                end else if(scan_code==8'hF0)begin
                    brk<=1'b1;
                end else begin
                    code_valid<=1'b1;
                    code<=scan_code;
                    is_break<=brk;
                    is_ext<=ext;
                    ext<=1'b0;
                    brk<=1'b0;
                end
            end
        end
    end
endmodule
