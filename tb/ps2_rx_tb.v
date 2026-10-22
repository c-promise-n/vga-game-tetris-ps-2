`timescale 1ns / 1ps
// Ps2_rx testbench: one PS/2 frame (start + 8 data + odd parity + stop).
module ps2_rx_tb;

    reg clk;
    reg rst_n;
    reg pclk = 1'b1;
    reg pdata = 1'b1;
    wire [7:0] scan_code;
    wire byte_valid;
    wire frame_error;
    wire parity_error;

    integer errors = 0;
    integer checks = 0;
    integer valid_cnt = 0;
    integer frame_cnt = 0;
    integer par_cnt = 0;
    integer k;
    reg [7:0] cap_code = 8'h00;
    reg prev_valid = 1'b0;
    reg prev_frame = 1'b0;
    reg prev_par = 1'b0;

    ps2_rx dut (
        .clk(clk),
        .rst_n(rst_n),
        .pclk(pclk),
        .pdata(pdata),
        .scan_code(scan_code),
        .byte_valid(byte_valid),
        .frame_error(frame_error),
        .parity_error(parity_error)
    );

    initial clk = 1'b0;
    always #5 clk = ~clk;

    always @(posedge clk) begin
        if (byte_valid === 1'b1) begin
            cap_code = scan_code;
            if (prev_valid !== 1'b1)
                valid_cnt = valid_cnt + 1;
        end
        if ((frame_error === 1'b1) && (prev_frame !== 1'b1))
            frame_cnt = frame_cnt + 1;
        if ((parity_error === 1'b1) && (prev_par !== 1'b1))
            par_cnt = par_cnt + 1;
        prev_valid = byte_valid;
        prev_frame = frame_error;
        prev_par = parity_error;
    end

    task clear_counters;
        begin
            valid_cnt = 0;
            frame_cnt = 0;
            par_cnt = 0;
            cap_code = 8'h00;
        end
    endtask

    task ps2_bit(input b);
        begin
            pdata = b;
            #20;
            pclk = 1'b0;
            #40;
            pclk = 1'b1;
            #40;
        end
    endtask

    // odd parity bit over data; inv_parity flips it to provoke a parity error
    task send_frame(input [7:0] d, input inv_parity, input bad_stop);
        integer i;
        reg p;
        begin
            p = ~(^d);
            if (inv_parity)
                p = ~p;
            ps2_bit(1'b0);
            for (i = 0; i < 8; i = i + 1)
                ps2_bit(d[i]);
            ps2_bit(p);
            ps2_bit(bad_stop ? 1'b0 : 1'b1);
            repeat (30) @(posedge clk);
        end
    endtask

    task expect_idle_flags(input [8*40-1:0] tag);
        begin
            checks = checks + 1;
            if ((byte_valid !== 1'b0) || (frame_error !== 1'b0) || (parity_error !== 1'b0)) begin
                errors = errors + 1;
                $display("FAIL %0s: flags not idle (valid=%b frame=%b parity=%b)",
                         tag, byte_valid, frame_error, parity_error);
            end
        end
    endtask

    task expect_byte(input [7:0] exp_code, input [8*40-1:0] tag);
        begin
            checks = checks + 1;
            if (valid_cnt !== 1) begin
                errors = errors + 1;
                $display("FAIL %0s: byte_valid count %0d, expected 1", tag, valid_cnt);
            end
            checks = checks + 1;
            if (cap_code !== exp_code) begin
                errors = errors + 1;
                $display("FAIL %0s: scan_code %02h, expected %02h", tag, cap_code, exp_code);
            end
            checks = checks + 1;
            if (frame_cnt !== 0) begin
                errors = errors + 1;
                $display("FAIL %0s: unexpected frame_error", tag);
            end
            checks = checks + 1;
            if (par_cnt !== 0) begin
                errors = errors + 1;
                $display("FAIL %0s: unexpected parity_error", tag);
            end
            repeat (3) @(posedge clk);
            expect_idle_flags(tag);
            clear_counters;
        end
    endtask

    task expect_parity_error(input [8*40-1:0] tag);
        begin
            checks = checks + 1;
            if (par_cnt < 1) begin
                errors = errors + 1;
                $display("FAIL %0s: parity_error not asserted", tag);
            end
            checks = checks + 1;
            if (valid_cnt !== 0) begin
                errors = errors + 1;
                $display("FAIL %0s: byte_valid asserted with bad parity", tag);
            end
            checks = checks + 1;
            if (frame_cnt !== 0) begin
                errors = errors + 1;
                $display("FAIL %0s: unexpected frame_error", tag);
            end
            repeat (3) @(posedge clk);
            expect_idle_flags(tag);
            clear_counters;
        end
    endtask

    task expect_frame_error(input [8*40-1:0] tag);
        begin
            checks = checks + 1;
            if (frame_cnt < 1) begin
                errors = errors + 1;
                $display("FAIL %0s: frame_error not asserted", tag);
            end
            checks = checks + 1;
            if (valid_cnt !== 0) begin
                errors = errors + 1;
                $display("FAIL %0s: byte_valid asserted with bad stop bit", tag);
            end
            repeat (3) @(posedge clk);
            expect_idle_flags(tag);
            clear_counters;
        end
    endtask

    initial begin
        #500000;
        $display("FAIL ps2_rx_tb: timeout");
        $finish;
    end

    initial begin
        rst_n = 1'b0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        repeat (10) @(negedge clk);

        // idle bus must not produce events
        repeat (20) @(posedge clk);
        checks = checks + 1;
        if ((valid_cnt != 0) || (frame_cnt != 0) || (par_cnt != 0)) begin
            errors = errors + 1;
            $display("FAIL idle bus produced events");
        end
        expect_idle_flags("after reset");
        clear_counters;

        send_frame(8'h1C, 1'b0, 1'b0);
        expect_byte(8'h1C, "make code 1C");

        send_frame(8'hF0, 1'b0, 1'b0);
        expect_byte(8'hF0, "break code F0");

        send_frame(8'hE0, 1'b0, 1'b0);
        expect_byte(8'hE0, "extended E0");

        send_frame(8'h75, 1'b0, 1'b0);
        expect_byte(8'h75, "extended key 75");

        send_frame(8'h29, 1'b0, 1'b0);
        expect_byte(8'h29, "make code 29");

        send_frame(8'h1C, 1'b1, 1'b0);
        expect_parity_error("bad parity");

        send_frame(8'h45, 1'b0, 1'b1);
        expect_frame_error("bad stop bit");

        // reset in the middle of a frame, then receive a clean one
        ps2_bit(1'b0);
        ps2_bit(1'b1);
        ps2_bit(1'b0);
        ps2_bit(1'b1);
        rst_n = 1'b0;
        repeat (3) @(negedge clk);
        rst_n = 1'b1;
        repeat (10) @(negedge clk);
        expect_idle_flags("after mid-frame reset");
        clear_counters;

        send_frame(8'h33, 1'b0, 1'b0);
        expect_byte(8'h33, "reset recovery");

        if (errors == 0)
            $display("PASS ps2_rx_tb (%0d checks)", checks);
        else
            $display("FAIL ps2_rx_tb (%0d errors / %0d checks)", errors, checks);
        $finish;
    end

endmodule
