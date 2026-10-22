`timescale 1ns / 1ps
// Pixel_pipe testbench
module pixel_pipe_tb;

    reg clk;
    reg rst_n;
    reg hsync_i;
    reg vsync_i;
    reg de_i;
    reg [11:0] rgb_i;
    wire hsync_o;
    wire vsync_o;
    wire [11:0] rgb_o;

    integer errors = 0;
    integer checks = 0;
    integer k;

    pixel_pipe dut (
        .clk(clk),
        .rst_n(rst_n),
        .hsync_i(hsync_i),
        .vsync_i(vsync_i),
        .de_i(de_i),
        .rgb_i(rgb_i),
        .hsync_o(hsync_o),
        .vsync_o(vsync_o),
        .rgb_o(rgb_o)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    task check(input [8*40-1:0] name, input integer got, input integer exp);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL %0s: got %0h, expected %0h", name, got, exp);
            end
        end
    endtask

    initial begin
        #5000;
        $display("FAIL pixel_pipe_tb: timeout");
        $finish;
    end

    initial begin
        rst_n = 1'b0;
        hsync_i = 1'b1;
        vsync_i = 1'b1;
        de_i = 1'b0;
        rgb_i = 12'h000;
        repeat (3) @(negedge clk);

        check("reset hsync_o", hsync_o, 1);
        check("reset vsync_o", vsync_o, 1);
        check("reset rgb_o", rgb_o, 12'h000);

        rst_n = 1'b1;

        // active pixel, syncs assert low
        @(negedge clk);
        hsync_i = 1'b0;
        vsync_i = 1'b0;
        de_i = 1'b1;
        rgb_i = 12'hABC;
        #1;
        check("no comb path hsync", hsync_o, 1);
        check("no comb path rgb", rgb_o, 12'h000);

        @(negedge clk);
        check("hsync latency", hsync_o, 0);
        check("vsync latency", vsync_o, 0);
        check("rgb latency", rgb_o, 12'hABC);

        // de low blanks rgb but syncs still pass
        @(negedge clk);
        hsync_i = 1'b1;
        vsync_i = 1'b1;
        de_i = 1'b0;
        rgb_i = 12'hFFF;
        @(negedge clk);
        check("blanked rgb", rgb_o, 12'h000);
        check("sync high latency", hsync_o, 1);
        check("vsync high latency", vsync_o, 1);

        // back-to-back pixels keep one clock offset
        for (k = 0; k < 8; k = k + 1) begin
            @(negedge clk);
            de_i = 1'b1;
            rgb_i = 12'h100 + k[11:0];
            @(negedge clk);
            check("stream rgb", rgb_o, 12'h100 + k);
        end

        // async reset clears the pipeline
        @(negedge clk);
        rst_n = 1'b0;
        #1;
        check("async reset hsync_o", hsync_o, 1);
        check("async reset vsync_o", vsync_o, 1);
        check("async reset rgb_o", rgb_o, 12'h000);

        if (errors == 0)
            $display("PASS pixel_pipe_tb (%0d checks)", checks);
        else
            $display("FAIL pixel_pipe_tb (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
