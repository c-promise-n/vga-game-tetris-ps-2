`timescale 1ns / 1ps
// Vga_timing testbench: 640x480@60
// 800 pixel clocks per line, 525 lines per frame, pixel_ce every 4th clock.
module vga_timing_tb;

    reg clk = 1'b1;
    reg rst_n;
    wire de;
    wire pixel_ce;
    wire [9:0] px;
    wire [9:0] py;
    wire hsync;
    wire vsync;

    integer errors = 0;
    integer checks = 0;
    integer gh = 0;
    integer gv = 0;
    integer lines = 0;
    integer frames = 0;
    integer clk_gap = 0;
    integer ce_seen = 0;
    integer de_line = 0;
    integer active_lines = 0;
    integer exp_obs;
    integer exp_px;
    integer exp_py;
    reg de_expected;
    wire [22:0] obs;

    localparam H_PIXELS = 800;
    localparam V_LINES = 525;
    localparam HS_END = 96;
    localparam HB = 144;
    localparam HE = 784;
    localparam VS_END = 2;
    localparam VB = 35;
    localparam VE = 515;

    vga_timing dut (
        .clk(clk),
        .rst_n(rst_n),
        .de(de),
        .pixel_ce(pixel_ce),
        .px(px),
        .py(py),
        .hsync(hsync),
        .vsync(vsync)
    );

    always #5 clk = ~clk;

    assign obs = {hsync, vsync, de, px, py};

    // Expected pixel counters
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gh <= 0;
            gv <= 0;
            lines <= 0;
            frames <= 0;
        end else if (pixel_ce) begin
            if (gh == H_PIXELS - 1) begin
                gh <= 0;
                lines <= lines + 1;
                if (gv == V_LINES - 1) begin
                    gv <= 0;
                    frames <= frames + 1;
                end else begin
                    gv <= gv + 1;
                end
            end else begin
                gh <= gh + 1;
            end
        end
    end

    task check(input [8*40-1:0] name, input integer got, input integer exp);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL %0s: got %0h, expected %0h (line %0d)", name, got, exp, lines);
            end
        end
    endtask

    // Check at every pixel strobe
    always @(negedge clk) begin
        if (!rst_n) begin
            clk_gap = 0;
            ce_seen = 0;
            de_line = 0;
            active_lines = 0;
            check("reset hsync", hsync, 0);
            check("reset vsync", vsync, 0);
            check("reset de", de, 0);
            check("reset px", px, 0);
            check("reset py", py, 0);
        end else if (pixel_ce) begin
            if (ce_seen)
                check("pixel_ce period", clk_gap, 4);
            ce_seen = 1;
            clk_gap = 1;

            de_expected = (gh >= HB) && (gh < HE) && (gv >= VB) && (gv < VE);
            if (de_expected) begin
                exp_px = gh - HB;
                exp_py = gv - VB;
            end else begin
                exp_px = 0;
                exp_py = 0;
            end
            exp_obs = { (gh > HS_END - 1),
                        (gv > VS_END - 1),
                        de_expected,
                        exp_px[9:0],
                        exp_py[9:0] };
            check("de/px/py/sync", obs, exp_obs);

            if (de)
                de_line = de_line + 1;
            if (gh == H_PIXELS - 1) begin
                if ((gv >= VB) && (gv < VE))
                    check("active pixels per line", de_line, 640);
                else
                    check("active pixels per line", de_line, 0);
                if (de_line != 0)
                    active_lines = active_lines + 1;
                de_line = 0;
            end
            if ((gh == 0) && (gv == 0) && (lines > 0)) begin
                check("active lines per frame", active_lines, 480);
                active_lines = 0;
            end


            if ((frames == 1) && (lines >= V_LINES + 2)) begin
                if (errors == 0)
                    $display("PASS vga_timing_tb (%0d checks)", checks);
                else
                    $display("FAIL vga_timing_tb (%0d errors / %0d checks)", errors, checks);
                $finish;
            end
        end else begin
            clk_gap = clk_gap + 1;
        end
    end

    initial begin
        #30000000;
        $display("FAIL vga_timing_tb: timeout");
        $finish;
    end

    initial begin
        rst_n = 1'b0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        repeat (2000) @(negedge clk);
        rst_n = 1'b0;
        repeat (5) @(negedge clk);
        rst_n = 1'b1;
    end

endmodule
