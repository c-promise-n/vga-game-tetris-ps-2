`timescale 1ns / 1ps
// Shape_rom testbench: all 7 brick types x 4 rotations
module shape_rom_tb;

    reg [2:0] bricktype;
    reg [1:0] rot;
    wire [15:0] mask;

    integer errors = 0;
    integer checks = 0;
    integer bt;
    integer r;
    reg [15:0] exp [0:27];

    shape_rom dut (
        .bricktype(bricktype),
        .rot(rot),
        .mask(mask)
    );

    function integer popcount(input [15:0] v);
        integer k;
        begin
            popcount = 0;
            for (k = 0; k < 16; k = k + 1)
                popcount = popcount + v[k];
        end
    endfunction

    task check(input [8*40-1:0] name, input integer got, input integer exp_val);
        begin
            checks = checks + 1;
            if (got !== exp_val) begin
                errors = errors + 1;
                if (errors <= 20)
                    $display("FAIL %0s: got %0h, expected %0h", name, got, exp_val);
            end
        end
    endtask

    initial begin
        #1000;
        $display("FAIL shape_rom_tb: timeout");
        $finish;
    end

    initial begin
        // I
        exp[0]  = 16'h00F0; exp[1]  = 16'h2222;
        exp[2]  = 16'h00F0; exp[3]  = 16'h2222;
        // O
        exp[4]  = 16'h0660; exp[5]  = 16'h0660;
        exp[6]  = 16'h0660; exp[7]  = 16'h0660;
        // T
        exp[8]  = 16'h0720; exp[9]  = 16'h0262;
        exp[10] = 16'h0270; exp[11] = 16'h0464;
        // S
        exp[12] = 16'h0360; exp[13] = 16'h0462;
        exp[14] = 16'h0360; exp[15] = 16'h0462;
        // Z
        exp[16] = 16'h0630; exp[17] = 16'h0264;
        exp[18] = 16'h0630; exp[19] = 16'h0264;
        // J
        exp[20] = 16'h0710; exp[21] = 16'h0226;
        exp[22] = 16'h0470; exp[23] = 16'h0644;
        // L
        exp[24] = 16'h0740; exp[25] = 16'h0622;
        exp[26] = 16'h0170; exp[27] = 16'h0446;

        bricktype = 3'd0;
        rot = 2'd0;
        #1;

        for (bt = 0; bt < 7; bt = bt + 1) begin
            for (r = 0; r < 4; r = r + 1) begin
                bricktype = bt[2:0];
                rot = r[1:0];
                #1;
                checks = checks + 1;
                if (mask !== exp[bt * 4 + r]) begin
                    errors = errors + 1;
                    if (errors <= 20)
                        $display("FAIL bricktype %0d rot %0d: got %0h, expected %0h",
                                 bt, r, mask, exp[bt * 4 + r]);
                end
                check("mask has 4 cells", popcount(mask), 4);
            end
        end

        // O is rotation invariant
        for (r = 1; r < 4; r = r + 1) begin
            bricktype = 3'd1;
            rot = r[1:0];
            #1;
            check("O rotation invariant", mask, 16'h0660);
        end

        // I alternates between horizontal and vertical
        bricktype = 3'd0;
        rot = 2'd0; #1; check("I rot0 horizontal", mask, 16'h00F0);
        rot = 2'd1; #1; check("I rot1 vertical", mask, 16'h2222);
        rot = 2'd2; #1; check("I rot2 same as rot0", mask, 16'h00F0);
        rot = 2'd3; #1; check("I rot3 same as rot1", mask, 16'h2222);

        // unused brick types fall through to the default mask
        for (bt = 7; bt < 8; bt = bt + 1) begin
            for (r = 0; r < 4; r = r + 1) begin
                bricktype = bt[2:0];
                rot = r[1:0];
                #1;
                check("unused brick type", mask, 16'h0000);
            end
        end

        if (errors == 0)
            $display("PASS shape_rom_tb (%0d checks)", checks);
        else
            $display("FAIL shape_rom_tb (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
