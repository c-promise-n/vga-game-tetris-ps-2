`timescale 1ns / 1ps
module key_repeat#(
    parameter  DAS=9,//delay auto shift
    parameter  ARR=3//Auto repeat rate
 )(
    input clk,
    input rst_n,
    input frame_tick,
    input key_pressed,
    output reg pulse

    );
    reg [3:0]cnt_das;
    reg [3:0]cnt_arr;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            pulse<=1'b0;
            cnt_das<=4'b0;
            cnt_arr<=4'b0;
        end else begin
            pulse<=1'b0;

            if(!key_pressed)begin
                cnt_das<=0;
                cnt_arr<=0;
            end else if(frame_tick)begin
            if(cnt_das<DAS) begin
                if(cnt_das==4'b0)begin
                    pulse<=1'b1;
                end
                cnt_das<=cnt_das+1'b1;
            end else begin
                if(cnt_arr==ARR-1)begin
                    cnt_arr<=4'b0;
                    pulse<=1'b1;
                end else begin
                    cnt_arr<=cnt_arr+1'b1;
                    end
                end
            end
        end
    end
endmodule
