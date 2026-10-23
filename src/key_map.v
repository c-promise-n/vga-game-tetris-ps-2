`timescale 1ns / 1ps
module key_map(
input  [7:0]code,
input   code_valid,
input   is_break,
input   is_ext,
input   clk,
input   rst_n,
output  reg [2:0]key_id,
output  reg key_down,
output  reg key_hit
);

//key_id: 0,left(E06B);
//        1,right(E074);
//        2,down(E072);
//        3,rotate(up)(E075);
//        4,drop(space)(29);
//        5,pause(P)(4D);
//        6,restart(R)(2D);
//        7,reset(esc)(76);

always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
        key_down<=1'b0;
        key_hit<=1'b0;
        key_id<=3'b0;
    end else begin
        key_hit<=1'b0;
        if(code_valid)begin
            if(is_break)begin
                key_down<=1'b0;
            end else begin
                key_down<=1'b1;
            end

            case ({is_ext,code})
                9'h1_6B:begin
                    key_id<=3'd0;
                    key_hit<=3'b1;
                end

                9'h1_74:begin
                    key_id<=3'd1;
                    key_hit<=3'b1;
                end

                9'h1_72:begin
                    key_id<=3'd2;
                    key_hit<=3'b1;
                end

                9'h1_75:begin
                    key_id<=3'd3;
                    key_hit<=3'b1;
                end

                9'h0_29:begin
                    key_id<=3'd4;
                    key_hit<=3'b1;
                end

                9'h0_4D:begin
                    key_id<=3'd5;
                    key_hit<=3'b1;
                end

                9'h0_2D:begin
                    key_id<=3'd6;
                    key_hit<=3'b1;
                end

                 9'h0_76:begin
                    key_id<=3'd7;
                    key_hit<=3'b1;
                end

                default: key_hit<=1'b0 ;
            endcase
        end
    end
end

endmodule
