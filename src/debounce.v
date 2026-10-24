`timescale 1ns / 1ps
module debounce#(parameter CNT_MAX=1_000_000)(
    input clk,
    input rst_n,
    input noisy_in,
    output reg clean_out
    );
    localparam CNT_WIDTH = $clog2(CNT_MAX+1);
    reg [CNT_WIDTH-1:0]cnt;
    reg stable;
    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <= {CNT_WIDTH{1'b0}};
            clean_out<=1'd0;
            stable<=1'b0;
        end else begin
            if(noisy_in!=stable)begin
                if(cnt == CNT_MAX)begin
                    stable    <=    noisy_in;
                    clean_out <=    noisy_in;
                    cnt       <=    {CNT_WIDTH{1'b0}};
                 end else begin
                    cnt <= cnt +1'b1;
                end
            end else begin
                cnt <= {CNT_WIDTH{1'b0}};
            end
        end
    end
endmodule
