`timescale 1ns / 1ps
// bit numbering scheme:bit index = drow*4 + dcol
//               drow = 0 topmost，dcol = 0 leftmost
//               bit0 = top-left corner，bit15 = bottom-right corner
// bricktype: 0=I 1=O 2=T 3=S 4=Z 5=J 6=L

module shape_rom(
    input  wire [2:0]  bricktype,
    input  wire [1:0]  rot,
    output reg  [15:0] mask
);
always @(*) begin
    case ({bricktype, rot})             // 5 bit index = bricktype*4 + rot
        // I
        5'd0:  mask = 16'h00F0;
        5'd1:  mask = 16'h2222;
        5'd2:  mask = 16'h00F0;
        5'd3:  mask = 16'h2222;
        // O
        5'd4:  mask = 16'h0660;
        5'd5:  mask = 16'h0660;
        5'd6:  mask = 16'h0660;
        5'd7:  mask = 16'h0660;
        //T
        5'd8:  mask = 16'h0720;
        5'd9:  mask = 16'h0262;
        5'd10: mask = 16'h0270;
        5'd11: mask = 16'h0464;
        //S
        5'd12: mask = 16'h0360;
        5'd13: mask = 16'h0462;
        5'd14: mask = 16'h0360;
        5'd15: mask = 16'h0462;
        //Z
        5'd16: mask = 16'h0630;
        5'd17: mask = 16'h0264;
        5'd18: mask = 16'h0630;
        5'd19: mask = 16'h0264;
        //J
        5'd20: mask = 16'h0710;
        5'd21: mask = 16'h0226;
        5'd22: mask = 16'h0470;
        5'd23: mask = 16'h0644;
        //L
        5'd24: mask = 16'h0740;
        5'd25: mask = 16'h0622;
        5'd26: mask = 16'h0170;
        5'd27: mask = 16'h0446;
        default: mask = 16'h0000;
    endcase
end
endmodule
