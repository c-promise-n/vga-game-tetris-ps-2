`timescale 1ns / 1ps
module piece_random(
input clk,
input rst_n,
input spawn,
output reg [2:0]piece_type
    );

    reg[7:0]used;
    reg[15:0]lfsr;
    wire[15:0]lfsr_nx;
    assign lfsr_nx={lfsr[14:0],lfsr[15] ^ lfsr[13] ^ lfsr[12] ^ lfsr[10]};

    wire [2:0]  cand;
    assign cand = lfsr[2:0];

    wire free;
    assign free=(cand<=3'd6)&&(!used[cand]);

    reg[2:0]first_free;
    always@(*)begin
        if(!used[0]) first_free=3'd0;
        else if(!used[1]) first_free=3'd1;
        else if(!used[2]) first_free=3'd2;
        else if(!used[3]) first_free=3'd3;
        else if(!used[4]) first_free=3'd4;
        else if(!used[5]) first_free=3'd5;
        else  first_free=3'd6;
    end

    reg[1:0]state;
    reg[3:0]retry;
    localparam INIT =2'd0,
                DRAW=2'd1,
                HOLD=2'd2;

    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            state<=INIT;
            lfsr<=16'hACE1;
            used<=8'b0;
            retry<=4'b0;
            piece_type<=3'b0;
        end else begin
            case(state)

            INIT:begin
                used<=8'd0;
                retry<=4'b0;
                state<=DRAW;
            end

            DRAW:begin
                if(free)begin
                    used[cand]<=1'b1;
                    piece_type<=cand;
                    retry<=4'b0;
                    state<=HOLD;
                end else if(retry==4'd7)begin
                    used[first_free]<=1'b1;
                    piece_type<=first_free;
                    retry<=4'd0;
                    lfsr<=lfsr_nx;
                    state<=HOLD;
                end else begin
                    lfsr<=lfsr_nx;
                    retry<=retry+4'd1;
                end
            end

            HOLD:begin
                if(spawn)begin
                    if(used[6:0]==7'h7F)begin
                        used<=8'd0;
                    end
                    retry<=4'd0;
                    state<=DRAW;
                end
                retry<=4'd0;
                state<=DRAW;
            end

            default:state<=INIT;
            endcase
        end
    end

endmodule
