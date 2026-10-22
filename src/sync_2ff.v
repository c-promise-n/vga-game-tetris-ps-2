`timescale 1ns / 1ps
module sync_2ff#(parameter width = 1)(
input clk,
input rst_n,
input [width-1:0]async_in,
output  [width-1:0]sync_out2,
output  [width-1:0]sync_out1
    );
reg [width-1:0]sync_0;
reg [width-1:0]sync_d1;
always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        sync_0<={width{1'b0}};
        sync_d1<={width{1'b0}};
    end else begin
        sync_0<=async_in;
        sync_d1<=sync_0;
    end
end
assign sync_out1=sync_0;
assign sync_out2=sync_d1;
endmodule
