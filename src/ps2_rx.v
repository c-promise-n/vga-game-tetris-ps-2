`timescale 1ns / 1ps
module ps2_rx(
    input clk,
    input rst_n,
    input pclk,
    input pdata,
    output reg[7:0]scan_code,
    output reg byte_valid,
    output reg frame_error,
    output reg parity_error
    );

    wire pclk_r2,pclk_r1;
    wire pdata_r2,pdata_r1;
    wire pclk_fall;

    sync_2ff pclk_sync_2ff (
        .clk      (clk),
        .rst_n    (rst_n),
        .async_in (pclk),
        .sync_out2(pclk_r2),
        .sync_out1(pclk_r1)
    );
    assign pclk_fall = pclk_r2 &(~pclk_r1);
    sync_2ff pdata_sync_2ff (
        .clk      (clk),
        .rst_n    (rst_n),
        .async_in (pdata),
        .sync_out2(pdata_r2),
        .sync_out1(pdata_r1)
    );

    localparam IDLE = 1'b0,
                DATA =1'b1;

    reg cur_state,next_state;
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            cur_state <= IDLE;
        end else begin
            cur_state <= next_state;
        end
    end

    reg [3:0]cnt;
    reg par;
    reg [7:0]shift;
    always @(*) begin
        next_state=cur_state;
        case(cur_state)

        IDLE:if(pclk_fall&&pdata_r2==1'b0)begin
            next_state = DATA;
        end else begin
            next_state = IDLE;
        end

        DATA:if(pclk_fall)begin
            if(cnt<=7)begin
                next_state=DATA;
            end else if(cnt == 8)begin
                next_state=DATA;
            end else begin
                next_state=IDLE;
            end
        end
        endcase
    end

    always@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            cnt <=4'b0;
            par<=1'b0;
            shift<=8'b0;
            frame_error<=1'b0;
            scan_code <=8'b0;
            byte_valid<=1'b0;
            parity_error<=1'b0;
        end else begin
            byte_valid<=1'b0;
            parity_error<=1'b0;
            frame_error<=1'b0;
            case(cur_state)
        IDLE:if(pclk_fall&&pdata_r2==1'b0)begin
            cnt <=4'b0;
        end

        DATA:if(pclk_fall)begin
            if(cnt<=7)begin
                shift <= {pdata_r2,shift[7:1]};
                cnt <= cnt + 4'b1;
            end else if(cnt == 8)begin
                cnt<=4'd9;
                par<=pdata_r2;
            end else begin
                if(pdata_r2!=1'b1) frame_error<=1'b1;
                else if((^shift^par)!=1'b1) parity_error<=1'b1;
                else begin
                    scan_code<=shift;
                    byte_valid<=1'b1;
                end
                cnt<=4'b0;
            end
        end
        endcase
        end
    end
endmodule
