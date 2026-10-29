`timescale 1ns / 1ps
module tetris_core(
input clk,
input rst_n,

input frame_tick,

input [7:0]key_pressed,
input [7:0]key_edge,
input move_left,
input move_right,

input [4:0]row_idx,
output [9:0]occ_row,
output [29:0]type_row,

output reg [2:0]p_type,
output reg [1:0]p_rot,
output reg [4:0]p_x,
output reg [4:0]p_y,
output reg [15:0]p_mask,

output reg[2:0]next_type,
output reg[15:0]next_mask,


output reg[15:0]score
  );

  shape_rom u_shape_rom (
    .bricktype(p_type),
    .rot      (p_rot),
    .mask     (p_mask)
  );
  shape_rom u_shape_rom_nx (
    .bricktype(next_type),
    .rot      (2'd0),
    .mask     (next_mask)
  );

  reg [9:0] field_occ [0:19];
  reg [29:0]field_type[0:19];

  assign occ_row=field_occ[row_idx];
  assign type_row=field_type[row_idx];

  reg   pr_spawn;
  wire[2:0]pr_type;
  piece_random u_pr (
    .clk       (clk),
    .rst_n     (rst_n),
    .spawn     (pr_spawn),
    .piece_type(pr_type)
  );

  function automatic collide;
    input[4:0]b_x;
    input[4:0]b_y;
    input [15:0]b_mask;
    integer i;
    reg[13:0]row_i;
    begin
      collide=1'b0;
      for(i=0;i<4;i=i+1)begin
        row_i={10'd0,b_mask[i*4 +: 4]};
        row_i=row_i>>b_x;
        if((b_y + i)>19)
        collide=1'd1;
        else if(row_i>14'h03FF)
        collide=1'b1;
        else if((row_i[9:0]&field_occ[b_y+i])!=10'b0)
        collide=1'b1;
      end
    end
  endfunction

  function [29:0]type_expand;
  input[9:0]occ_mask;
  input[2:0]b_type;
  integer i;
  begin
    type_expand=30'd0;
    for(i=0;i<10;i=i+1)begin
      if(occ_mask[i]) type_expand[3*i+:3]=b_type;
    end
  end
  endfunction

  localparam IDLE =2'd0 ,
             PLAY=2'd1 ,
             PAUSE=2'd2,
             OVER=2'd3;
  reg game_over;
  reg [1:0]cur_state,next_state;
  wire start_paulse,restart_paulse,pause_pulse;
  assign start_paulse=key_edge[7]|key_edge[6];
  assign restart_paulse=key_edge[6];
  assign pause_pulse=key_edge[5];
  always @(posedge clk or negedge rst_n) begin
    if(!rst_n)begin
      cur_state<=IDLE;
    end else begin
      cur_state<=next_state;
    end
  end

  always @(*) begin
    next_state=cur_state;
    case (cur_state)
      IDLE:if(start_paulse) next_state=PLAY;

      PLAY:if(pause_pulse) next_state=PAUSE;
        else if(game_over) next_state=OVER;

      PAUSE:if(pause_pulse)next_state=PLAY;

      OVER:if(restart_paulse)next_state=PLAY;
      default:next_state=IDLE;
    endcase
  end

  integer r,j;
  wire landed;
  wire piece_active=(cur_state==PLAY);
  reg spawn_pending;
  reg[13:0]row_j;
  assign landed=collide(p_x, p_y +5'd1/* logic[4:0] */, p_mask /* logic[15:0] */);

 localparam GRAV =8'd30;
 reg [7:0]grav_cnt;

  always@(posedge clk or negedge rst_n)begin
    if(!rst_n)begin
      for(r=0;r<20;r=r+1)begin
        field_occ[r]<=10'd0;
        field_type[r]<=30'd0;
      end
      p_type  <=3'd0;
      p_rot   <=2'd0;
      p_x     <=5'd0;
      p_y     <=5'd0;
      next_type<=3'd0;
      pr_spawn<=1'b0;
      spawn_pending<=1'b0;
      grav_cnt<=1'b0;
      game_over<=1'b0;
    end else begin
      pr_spawn<=1'b0;
      game_over<=1'b0;
      if(piece_active && move_left && !move_right)begin
        if(!collide(p_x-5'd1 /* logic[4:0] */, p_y /* logic[4:0] */, p_mask /* logic[15:0] */))begin
          p_x=p_x-1'b1;
        end
      end

      if(piece_active && !move_left && move_right)begin
        if(!collide(p_x+5'd1 /* logic[4:0] */, p_y /* logic[4:0] */, p_mask /* logic[15:0] */))begin
          p_x=p_x+1'b1;
        end
      end

      if(frame_tick && piece_active)begin
        if(!landed)begin
          if(grav_cnt == GRAV-1'b1)begin
            grav_cnt<=8'd0;
            p_y<=p_y+5'd1;
          end else begin
            grav_cnt<=grav_cnt+8'd1;
          end
        end else begin
          for(j=0;j<4;j=j+1)begin
            row_j={10'd0,p_mask[j*4 +: 4]};
            row_j=row_j>>p_x;
            if((p_y+1<=19)&&(row_j>14'h03FF))begin
              field_occ[p_y+j]<=field_occ[p_y+j] | row_j[9:0];
              field_type[p_y+j]<=field_type[p_y+j]|type_expand(field_occ[p_y+j] /* logic[9:0] */, p_type /* logic[2:0] */);
            end
          end
        spawn_pending<=1'b1;
        grav_cnt<=8'd0;
        end

        if(spawn_pending)begin
          p_type<=next_type;
          p_rot<=2'b0;
          p_x=5'd3;
          p_y=5'd0;
          next_type<=pr_type;
          pr_spawn<=1'b1;
          spawn_pending<=1'b0;
          if(collide(5'd3, 5'd0 /* logic[4:0] */, next_mask /* logic[15:0] */)) game_over<=1'b0;
        end
      end

    end
  end
endmodule
