`timescale 1ns / 1ps
// top_demo1 - Basys3 Tetris top level, DEMO build (no tetris_core)
// Purpose
//   Verify the whole VGA chain on real hardware without the game core:
//     vga_timing -> cell_map -> render -> palette -> pixel_pipe
// Switch usage (DEMO only)
//   sw[3:0]   piece column p_x
//   sw[7:4]   piece row    p_y
//   sw[10:8]  piece type(I O T S Z J L)
//   sw[12:11] piece rotation
// LED usage
//   led[4:0]   col_idx latched at (px=120, py=240)
//   led[9:5]   row_idx latched at (px=120, py=240)
//   led[15]    heartbeat from frame_tick, ~1 Hz
//======================================================================
module top_demo1 (
    input  wire        clk,        // W5  100 MHz
    input  wire        btn_c,      // U18 center button, active high
    input  wire [15:0] sw,
    output wire [15:0] led,
    output wire [3:0]  vga_r,
    output wire [3:0]  vga_g,
    output wire [3:0]  vga_b,
    output wire        vga_hs,
    output wire        vga_vs
);

    wire rst_n = ~btn_c;
    wire [9:0] px, py;
    wire       de, pixel_ce, hsync, vsync, frame_tick;

    vga_timing u_vga (
        .clk        (clk),
        .rst_n      (rst_n),
        .de         (de),
        .pixel_ce   (pixel_ce),
        .frame_tick (frame_tick),
        .px         (px),
        .py         (py),
        .hsync      (hsync),
        .vsync      (vsync)
    );

    wire [4:0] col_idx, row_idx;
    wire [3:0] col_px,  row_px;

    cell_map u_cell (
        .clk      (clk),
        .rst_n    (rst_n),
        .de       (de),
        .pixel_ce (pixel_ce),
        .px       (px),
        .py       (py),
        .col_idx  (col_idx),
        .row_idx  (row_idx),
        .col_px   (col_px),
        .row_px   (row_px)
    );

    wire [8:0] px_log = px[9:1];

    function [9:0] demo_occ;
        input [4:0] r;
        begin
            case (r)
                5'd19: demo_occ = 10'b1111111111;
                5'd18: demo_occ = 10'b1111111111;
                5'd17: demo_occ = 10'b0111000111;  // columns 3..5 empty
                default: demo_occ = 10'b0000000000;
            endcase
        end
    endfunction

    function [29:0] demo_type; 
        input [4:0] r;
        begin
            case (r)
                5'd19: demo_type = {10{3'd4}};
                5'd18: demo_type = {10{3'd2}};
                5'd17: demo_type = {3'd0, 3'd6, 3'd6, 3'd6,
                                    3'd0, 3'd0, 3'd0,
                                    3'd5, 3'd5, 3'd5};
                default: demo_type = 30'd0;
            endcase
        end
    endfunction

    wire [9:0]  field_occ_row  = demo_occ (row_idx);
    wire [29:0] field_type_row = demo_type(row_idx);
    wire [2:0] p_type = (sw[10:8] > 3'd6) ? 3'd6 : sw[10:8];
    wire [1:0] p_rot  = sw[12:11];
    wire [4:0] p_x    = (sw[3:0] > 4'd9) ? 5'd9 : {1'b0, sw[3:0]};
    wire [4:0] p_y    = {1'b0, sw[7:4]};

    wire [15:0] shape_mask;
    shape_rom u_shape (
        .bricktype (p_type),
        .rot       (p_rot),
        .mask      (shape_mask)
    );
    wire [3:0] color_idx;

    render u_render (
        .px_log         (px_log),
        .col_idx        (col_idx),
        .row_idx        (row_idx),
        .col_px         (col_px),
        .row_px         (row_px),
        .p_type         (p_type),
        .p_x            (p_x),
        .p_y            (p_y),
        .shape_mask     (shape_mask),
        .field_occ_row  (field_occ_row),
        .field_type_row (field_type_row),
        .color_idx      (color_idx)
    );

    //------------------------------------------------------------------
    // 7. Palette : 4-bit index -> 12-bit RGB
    //------------------------------------------------------------------
    wire [11:0] rgb;
    palette u_pal (
        .index (color_idx),
        .rgb   (rgb)
    );

    //------------------------------------------------------------------
    // 8. Output pipeline register -> pins
    //    rgb / hsync / vsync / de are registered on the same clock, which
    //    keeps them aligned and removes combinational glitches.
    //------------------------------------------------------------------
    wire [11:0] rgb_o;

    pixel_pipe u_pipe (
        .clk     (clk),
        .rst_n   (rst_n),
        .hsync_i (hsync),
        .vsync_i (vsync),
        .rgb_i   (rgb),
        .de_i    (de),
        .hsync_o (vga_hs),
        .vsync_o (vga_vs),
        .rgb_o   (rgb_o)
    );

    assign vga_r = rgb_o[11:8];
    assign vga_g = rgb_o[7:4];
    assign vga_b = rgb_o[3:0];

    //------------------------------------------------------------------
    // 9. LED self-check : latch cell coordinates at a known pixel
    //    At px=120 -> px_log=60 -> col_idx = 60/12 = 5
    //    At py=240 -> py_log=120 -> row_idx = 120/12 = 10
    //    If led[4:0] shows 10 instead of 5, cell_map is still counting
    //    physical pixels instead of logical ones.
    //------------------------------------------------------------------
    reg  [9:0] probe;
    wire probe_tick = pixel_ce && de && (px == 10'd120) && (py == 10'd240);

    always @(posedge clk) begin
        if (probe_tick) probe <= {col_idx, row_idx};
    end

    assign led[4:0] = probe[4:0];       // col_idx, expect 5
    assign led[9:5] = probe[9:5];       // row_idx, expect 10

    //------------------------------------------------------------------
    // 10. Heartbeat LED from frame_tick, toggles every 30 frames ~ 1 Hz
    //     With a monitor this is a quick sanity check; without one it is
    //     the only proof that the timing chain is alive.
    //------------------------------------------------------------------
    reg [4:0] hb_cnt;
    reg       hb;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hb_cnt <= 5'd0;
            hb     <= 1'b0;
        end else if (frame_tick) begin
            if (hb_cnt == 5'd29) begin
                hb_cnt <= 5'd0;
                hb     <= ~hb;
            end else begin
                hb_cnt <= hb_cnt + 5'd1;
            end
        end
    end

    assign led[15]    = hb;             // ~1 Hz heartbeat
    assign led[14:10] = 5'b00000;

endmodule
