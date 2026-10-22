`timescale 1ns / 1ps
// Cell_map testbench: pixel to cell coordinate mapping over one full 640x480 frame.
// Expected: col_idx = (px/24)%27, col_px = (px/2)%12,
//           row_idx = (py/24)%20, row_px = (py/2)%12.
module cell_map_tb;

    reg clk = 1'b0;
    reg rst_n;
    reg de;
    reg pixel_ce;
    reg [9:0] px;
    reg [9:0] py;
    wire [4:0] col_idx;
    wire [4:0] row_idx;
    wire [3:0] col_px;
    wire [3:0] row_px;

    integer errors = 0;
    integer checks = 0;
    integer x_cnt = 0;
    integer y_cnt = 0;
    integer drive_en = 0;
    integer have_exp = 0;
    integer exp_hold = 0;
    integer last_v = 0;
    integer e_col_idx;
    integer e_row_idx;
    integer e_col_px;
    integer e_row_px;

    wire [17:0] obs = {col_idx, row_idx, col_px, row_px};

    cell_map dut (
        .clk(clk),
        .rst_n(rst_n),
        .de(de),
        .pixel_ce(pixel_ce),
        .px(px),
        .py(py),
        .col_idx(col_idx),
        .row_idx(row_idx),
        .col_px(col_px),
        .row_px(row_px)
    );

    always #5 clk = ~clk;

    task check(input [8*40-1:0] name, input integer got, input integer exp);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL %0s: got %0h, expected %0h (px=%0d py=%0d)",
                             name, got, exp, px, py);
            end
        end
    endtask

    initial begin
        #40000000;
        $display("FAIL cell_map_tb: timeout");
        $finish;
    end

    always @(negedge clk) begin
        if (!rst_n) begin
            x_cnt = 0;
            y_cnt = 0;
            have_exp = 0;
        end else if (drive_en != 0) begin
            if (have_exp != 0)
                check("cell mapping", obs, exp_hold);

            px = x_cnt[9:0];
            py = y_cnt[9:0];
            de = 1'b1;
            pixel_ce = 1'b1;
            e_col_idx = (x_cnt / 24) % 27;
            e_row_idx = (y_cnt / 24) % 20;
            e_col_px = (x_cnt / 2) % 12;
            e_row_px = (y_cnt / 2) % 12;
            exp_hold = {e_col_idx[4:0], e_row_idx[4:0], e_col_px[3:0], e_row_px[3:0]};
            have_exp = 1;

            if (x_cnt == 639) begin
                x_cnt = 0;
                if (y_cnt == 479)
                    drive_en = 0;
                else
                    y_cnt = y_cnt + 1;
            end else begin
                x_cnt = x_cnt + 1;
            end
        end
    end

    initial begin
        rst_n = 1'b0;
        de = 1'b1;
        pixel_ce = 1'b1;
        px = 10'd0;
        py = 10'd0;
        repeat (3) @(negedge clk);

        check("reset col_idx", col_idx, 0);
        check("reset row_idx", row_idx, 0);
        check("reset col_px", col_px, 0);
        check("reset row_px", row_px, 0);

        rst_n = 1'b1;
        drive_en = 1;
        wait (drive_en == 0);
        @(negedge clk);
        check("cell mapping last pixel", obs, exp_hold);
        last_v = obs;
        pixel_ce = 1'b0;

        // pixel_ce low: outputs hold
        px = 10'd100;
        py = 10'd100;
        @(negedge clk);
        check("hold on pixel_ce low", obs, last_v);

        // de low: outputs hold
        pixel_ce = 1'b1;
        de = 1'b0;
        px = 10'd200;
        py = 10'd200;
        @(negedge clk);
        check("hold on de low", obs, last_v);

        // async reset clears all outputs
        rst_n = 1'b0;
        #1;
        check("async reset", obs, 0);

        // restart from the first active pixel
        rst_n = 1'b1;
        de = 1'b1;
        pixel_ce = 1'b1;
        px = 10'd0;
        py = 10'd0;
        @(negedge clk);
        check("restart at frame start", obs, 0);

        if (errors == 0)
            $display("PASS cell_map_tb (%0d checks)", checks);
        else
            $display("FAIL cell_map_tb (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
