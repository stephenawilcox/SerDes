/*
Copyright (c) 2025 Stephen Wilcox. All rights reserved
Not for use in commercial or non-commercial products or projects.
*/
module serializer #(
    parameter integer in_bit_width = 512,
    parameter integer out_bit_width = 32
)
(
    input wire clk,
    input wire reset,
    input wire data_ready,
    output reg read_data,
    input wire [in_bit_width-1:0] data_in,
    output reg write_data,
    output reg [out_bit_width-1:0] data_out
);

localparam integer num_segments = in_bit_width / out_bit_width;
localparam integer seg_ctr_bw   = $clog2(num_segments);

// 2 states, BUSY is for when it's serializing the buffer
localparam IDLE = 1'b0, BUSY = 1'b1;

reg current_state, next_state;
reg [in_bit_width-1:0] buffer;                      // the parallel data being serialized
reg [seg_ctr_bw-1:0] seg_counter;                   // the segment in the buffer to output
reg [seg_ctr_bw-1:0] seg_counter_q;                 // next seg_counter
wire seg_ctr_all_ones;                              // if segment counter is all ones it is on last segment of current buffer

assign seg_ctr_all_ones = &seg_counter;             // reduction AND on seg_counter

// the output data, each segment is wired to buffer to support higher clock freq
reg [out_bit_width-1:0] out_buffer [num_segments]; 
genvar i;
generate
    for (i = 1; i <= num_segments; i++) begin
        assign out_buffer[i-1] = buffer[out_bit_width*i - 1: out_bit_width * (i-1)];
    end
endgenerate

//STATE TRANSITION LOGIC
always @(*) begin
	case (current_state)
		IDLE: begin
			next_state = data_ready ? BUSY : IDLE; 
		end
		BUSY: begin
			next_state = seg_ctr_all_ones ? (data_ready ? BUSY : IDLE) : BUSY;
		end
		default:
			next_state = IDLE;
	endcase
end

always @(posedge clk) begin
    if (reset) begin
        current_state <= IDLE;
        buffer <= 0;
        seg_counter <= 0;
    end
    else begin
        current_state <= next_state;
        buffer <= read_data ? data_in : buffer;
        seg_counter <= seg_counter_q;
    end
end

//OUTPUT LOGIC
always @ (*) begin
    // localparam IDLE = 1'b0, BUSY = 1'b1; --> current_state will be IDLE or BUSY
    read_data = (!current_state & data_ready) | (seg_ctr_all_ones & data_ready);
    write_data = current_state;
    seg_counter_q = current_state ? (seg_counter + current_state) : 0; 
    data_out = out_buffer[seg_counter];
end

endmodule