`timescale 1ns / 1ps
//======================================================================
// tb_frame - dump one full frame to a PPM image
//
// Intended use
//   1. add this file to Simulation Sources
//   2. Run Simulation -> Run All
//   3. the console prints the frame period and the pixel count
//   4. convert the image:
//        python tools/ppm2png.py frame.ppm frame.png
//
// What it checks
//   - frame period should be 16 800 000 ns (= 800*525*4 * 10 ns)
//   - visible pixels per frame should be 307 200 (= 640*480)
//   If either differs, the timing parameters are wrong; fix that before
//   looking at the picture itself.
//
// Note on time formatting
//   $time is printed with %0d (unit = the module timeunit = 1 ns).
//   Do NOT use %t here: XSim formats %t in the global precision (1 ps),
//   which makes the number look 1000x too large.
//======================================================================
module tb_frame;

    //------------------------------------------------------------------
    // Clock and reset
    //------------------------------------------------------------------
    reg clk   = 1'b0;
    reg btn_c = 1'b1;                   // hold reset at time 0
    always #5 clk = ~clk;               // 100 MHz, period 10 ns

    //------------------------------------------------------------------
    // Demo switch setting: type=T(2), rot=0, x=3, y=6
    //   sw[3:0]=3  sw[7:4]=6  sw[10:8]=2  sw[12:11]=0
    //------------------------------------------------------------------
    reg [15:0] sw = 16'h0263;

    wire [3:0]  vga_r, vga_g, vga_b;
    wire        vga_hs, vga_vs;
    wire [15:0] led;

    top_demo1 u_top (
        .clk    (clk),
        .btn_c  (btn_c),
        .sw     (sw),
        .led    (led),
        .vga_r  (vga_r),
        .vga_g  (vga_g),
        .vga_b  (vga_b),
        .vga_hs (vga_hs),
        .vga_vs (vga_vs)
    );

    //------------------------------------------------------------------
    // Frame delimiter: falling edge of vsync (active low)
    //------------------------------------------------------------------
    reg  vs_d = 1'b1;
    always @(posedge clk) vs_d <= vga_vs;
    wire frame_start = vs_d & ~vga_vs;

    integer frame    = 0;
    integer n_pixels = 0;
    integer fd;
    time    t_prev   = 0;
    reg     finished = 1'b0;

    //------------------------------------------------------------------
    // Open the PPM file (P3, ASCII)
    //------------------------------------------------------------------
    initial begin
        fd = $fopen("frame.ppm", "w");
        if (fd == 0) begin
            $display("ERROR: cannot create frame.ppm");
            $finish;
        end
        $fdisplay(fd, "P3");
        $fdisplay(fd, "640 480");
        $fdisplay(fd, "255");
        $display("Start simulation, frame 3 will be dumped ...");
    end

    // release reset after 200 ns
    initial begin
        #200 btn_c = 1'b0;
    end

    //------------------------------------------------------------------
    // Frame statistics and dump of frame index 2 (the third frame)
    //
    // frame is incremented at every vsync falling edge, so the value
    // seen by the rest of this block is the index of the CURRENT frame.
    // n_pixels starts at 0 and is only incremented while frame == 2, so
    // it must NOT be cleared again (clearing it at the vsync edge of
    // frame 3 would wipe the result just before it is printed).
    //------------------------------------------------------------------
    always @(posedge clk) begin

        if (frame_start) begin
            frame <= frame + 1;
            if (t_prev != 0)
                $display("frame %0d, period = %0d ns (expect 16800000)",
                         frame, ($time - t_prev));
            t_prev = $time;
        end

        // one sample per physical pixel (pixel_ce is the 25 MHz strobe)
        if (frame == 2 && u_top.pixel_ce && u_top.de) begin
            $fdisplay(fd, "%0d %0d %0d",
                      vga_r * 17, vga_g * 17, vga_b * 17);
            n_pixels <= n_pixels + 1;
        end

        if (frame == 3 && !finished) begin
            finished <= 1'b1;
            $fclose(fd);
            $display("----------------------------------------");
            $display("pixels per frame = %0d (expect 307200)", n_pixels);
            if (n_pixels != 640*480)
                $display("FAIL: check hdat_end / vdat_end");
            else
                $display("PASS: timing parameters are correct");
            $display("----------------------------------------");
            $finish;
        end
    end

    // watchdog
    initial begin
        #50_000_000;
        $display("FAIL: timeout");
        $finish;
    end

endmodule
