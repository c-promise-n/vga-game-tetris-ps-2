`timescale 1ns / 1ps
module scan_ctrl(

input clk,
input rst_n,
input [3:0]data0,data1,data2,data3,//from right to left
input [3:0]dp_mask,
input blank,
output reg [3:0] an,
output [6:0]seg,
output reg dp
    );
    reg [15:0]scan_div;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            scan_div <= 16'b0;
        end else begin
            scan_div <= scan_div + 1'b1;
        end
    end
    wire [1:0] scan_cnt;
    assign scan_cnt =scan_div[15:14];

    reg[3:0]cur_data;
    always@(*)begin
        dp=1'b1;
        case(scan_cnt)

            2'b00:begin
                an=4'b1110;
                cur_data=data0 ;
                dp = ~dp_mask[0];
            end

            2'b01:begin
                an=4'b1101;
                cur_data=data1;
                dp = ~dp_mask[1];
            end

            2'b10:begin
                an=4'b1011;
                cur_data=data2;
                dp = ~dp_mask[2];
            end

            2'b11:begin
                an=4'b0111;
                cur_data=data3;
                dp = ~dp_mask[3];
            end
        endcase
        if(blank)begin
            an=4'b1111;
            dp=1'b1;
            cur_data=4'hF;
        end
    end
    seg_decoder seg_decoder (
        .bin(cur_data),
        .seg(seg)
    );
endmodule
