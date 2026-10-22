`timescale 1ns / 1ps
// Render testbench: region decoding, grid, field contents, piece priority, type mapping.
module render_tb;

    reg [8:0] px_log;
    reg [4:0] col_idx;
    reg [4:0] row_idx;
    reg [3:0] col_px;
    reg [3:0] row_px;
    reg [2:0] p_type;
    reg [4:0] p_x;
    reg [4:0] p_y;
    reg [15:0] shape_mask;
    reg [9:0] field_occ_row;
    reg [29:0] field_type_row;
    wire [3:0] color_idx;

    integer errors = 0;
    integer checks = 0;
    integer i;
    integer c;
    integer r;
    integer exp_v;

    render dut (
        .px_log(px_log),
        .col_idx(col_idx),
        .row_idx(row_idx),
        .col_px(col_px),
        .row_px(row_px),
        .p_type(p_type),
        .p_x(p_x),
        .p_y(p_y),
        .shape_mask(shape_mask),
        .field_occ_row(field_occ_row),
        .field_type_row(field_type_row),
        .color_idx(color_idx)
    );

    task check(input [8*40-1:0] name, input integer got, input integer exp);
        begin
            checks = checks + 1;
            if (got !== exp) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL %0s: got %0h, expected %0h (col=%0d row=%0d)",
                             name, got, exp, col_idx, row_idx);
            end
        end
    endtask

    initial begin
        #100000;
        $display("FAIL render_tb: timeout");
        $finish;
    end

    initial begin
        p_type = 3'd0;
        p_x = 5'd0;
        p_y = 5'd0;
        shape_mask = 16'h0000;
        field_occ_row = 10'h000;
        field_type_row = 30'h00000000;
        px_log = 9'd0;
        col_idx = 5'd5;
        row_idx = 5'd5;
        col_px = 4'd5;
        row_px = 4'd5;
        #1;

        // horizontal region: field, border, panel
        for (i = 0; i < 512; i = i + 1) begin
            px_log = i[8:0];
            #1;
            if (i <= 119)
                exp_v = 4'hE;
            else if (i < 132)
                exp_v = 4'hD;
            else
                exp_v = 4'hF;
            check("region decode", color_idx, exp_v);
        end

        // grid lines inside the field
        px_log = 9'd50;
        row_idx = 5'd5;
        row_px = 4'd5;
        for (i = 0; i < 16; i = i + 1) begin
            col_px = i[3:0];
            #1;
            check("column grid", color_idx, (i == 0) ? 4'h1 : 4'hE);
        end
        col_px = 4'd5;
        for (i = 0; i < 16; i = i + 1) begin
            row_px = i[3:0];
            #1;
            check("row grid", color_idx, (i == 0) ? 4'h1 : 4'hE);
        end
        row_px = 4'd5;

        // occupied field: cell type + 2, cell index above 9 clamps to cell 0
        field_occ_row = 10'h3FF;
        field_type_row = 30'h00000000;
        for (c = 0; c < 10; c = c + 1)
            field_type_row[3*c +: 3] = c[2:0];
        for (c = 0; c < 32; c = c + 1) begin
            col_idx = c[4:0];
            #1;
            if (c <= 9)
                exp_v = c[2:0] + 4'h2;
            else
                exp_v = 4'h2;
            check("occupied cell type", color_idx, exp_v);
        end

        // occupancy beats grid
        col_idx = 5'd3;
        col_px = 4'd0;
        #1;
        check("occupancy beats grid", color_idx, 4'h5);
        col_px = 4'd5;

        // piece hit area with full mask, no occupancy
        field_occ_row = 10'h000;
        field_type_row = 30'h00000000;
        px_log = 9'd50;
        p_type = 3'd2;
        p_x = 5'd5;
        p_y = 5'd7;
        shape_mask = 16'hFFFF;
        for (r = 0; r < 32; r = r + 1) begin
            row_idx = r[4:0];
            for (c = 0; c < 32; c = c + 1) begin
                col_idx = c[4:0];
                #1;
                if ((r >= 7) && (r <= 10) && (c >= 5) && (c <= 8))
                    exp_v = 4'h4;
                else
                    exp_v = 4'hE;
                check("piece hit area", color_idx, exp_v);
            end
        end

        // single cell mask only hits its own cell
        shape_mask = 16'h0001;
        row_idx = 5'd7;
        col_idx = 5'd5;
        #1;
        check("mask bit 0 hit", color_idx, 4'h4);
        col_idx = 5'd6;
        #1;
        check("mask bit 0 miss", color_idx, 4'hE);
        col_idx = 5'd5;
        row_idx = 5'd8;
        #1;
        check("mask bit 0 miss row", color_idx, 4'hE);

        // piece type mapping
        row_idx = 5'd7;
        col_idx = 5'd5;
        for (i = 0; i < 7; i = i + 1) begin
            p_type = i[2:0];
            #1;
            check("piece color map", color_idx, i + 2);
        end

        // field cell type mapping
        p_type = 3'd0;
        shape_mask = 16'h0000;
        field_occ_row = 10'h001;
        col_idx = 5'd0;
        for (i = 0; i < 7; i = i + 1) begin
            field_type_row[2:0] = i[2:0];
            #1;
            check("field color map", color_idx, i + 2);
        end

        // priority: hit > occupancy > grid
        field_occ_row = 10'h3FF;
        field_type_row = 30'h00000000;
        field_type_row[8:0] = 9'd1;
        p_type = 3'd6;
        shape_mask = 16'hFFFF;
        p_x = 5'd0;
        p_y = 5'd0;
        row_idx = 5'd0;
        col_idx = 5'd0;
        col_px = 4'd0;
        row_px = 4'd0;
        #1;
        check("hit beats occupancy and grid", color_idx, 4'h8);

        // outside the field the piece and field content are ignored
        px_log = 9'd125;
        #1;
        check("border ignores content", color_idx, 4'hD);
        px_log = 9'd200;
        #1;
        check("panel ignores content", color_idx, 4'hF);

        if (errors == 0)
            $display("PASS render_tb (%0d checks)", checks);
        else
            $display("FAIL render_tb (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
