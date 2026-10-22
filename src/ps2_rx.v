`timescale 1ns / 1ps
module ps2_rx(
    input clk,
    input rst_n,
    input pclk,
    input pdata,
    output reg[7:0]scan_code,
    output reg byte_valid
    );

    wire pclk_r2,pclk_r1;
    wire pdata_r2,pdata_r1;
    wire pclk_fall;

    sync_2ff #(
    .width(/* default 1 */)
    ) pclk_sync_2ff (
        .clk      (clk),
        .rst_n    (rst_n),
        .async_in (pclk),
        .sync_out2(pclk_r2),
        .sync_out1(pclk_r1)
    );
    assign pclk_fall = pclk_r2 &(~pclk_r1);
    sync_2ff #(
        .width(/* default 1 */)
     ) sync_2ff (
        .clk      (clk),
        .rst_n    (rst_n),
        .async_in (pdata),
        .sync_out2(pdata_r2),
        .sync_out1(pdata_r1)
    );

    localparam IDLE = 1'b0,
                BIT =1'B1;

    reg cur_state,next_state;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            cur_state <= IDLE;
        end else begin
            cur_state <= next_state;
        end
    end

    reg [2:0]cnt;
    always @(*) begin
        next_state=cur_state;
        case(cur_state)

        IDLE:if(pclk_fall&&pdata_r2==0)begin
            next_state = BIT;
            cnt =3'b0;
        end else begin
            byte_valid=1'b0;
            next_state = IDLE;
        end

        BIT:if(pclk_fall)begin
            scan_code = {pdata_r2,scan_code[7:1]};
            next_state=BIT;
            cnt =cnt +1;
        end else if(cnt==3'd7)begin
            byte_valid =1'b1;
            cnt=3'b0;
            next_state=IDLE;
        end
        endcase
    end
endmodule
