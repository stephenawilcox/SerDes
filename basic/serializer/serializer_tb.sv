/*
Copyright (c) 2025 Stephen Wilcox. All rights reserved.
Not for use in commercial or non-commercial products or projects without explicit permission from author.
*/
`timescale 1ns/1ps
module serializer_tb();
    parameter integer in_bit_width = 512;
    parameter integer out_bit_width = 32;

    reg clk, reset;

    reg data_ready;
    reg [in_bit_width-1:0] data_in;

    wire read_data, write_data;
    wire [out_bit_width-1:0] data_out;

    integer num_segments = in_bit_width / out_bit_width;

    reg [out_bit_width-1:0] data [16];
    reg [out_bit_width-1:0] prev_data_out;

    integer i, j, rd_count, wr_count;

    serializer #(.in_bit_width(in_bit_width), .out_bit_width(out_bit_width)) ser_inst (
        .clk(clk),
        .reset(reset),
        .data_ready(data_ready),
        .read_data(read_data),
        .data_in(data_in),
        .write_data(write_data),
        .data_out(data_out)
    );


    initial begin
        $dumpfile("serializer.vcd");
        $dumpvars(0, serializer_tb);

        rd_count = 0;
        wr_count = 0;
        prev_data_out = 0;

        reset = 1;
        clk = 0;
        #20;
        reset = 0;
        
        data_ready = 1;

        for (j = 0; j < 256; j++) begin
            if (read_data) begin
                //setting data
                for (i = 0; i < num_segments; i++) begin
                    data[i] = i + (rd_count * num_segments);
                end
                //setting data_in
                for (i = 1; i <= num_segments; i++) begin
                    //data_in[out_bit_width*i - 1: out_bit_width * (i-1)] = data[i-1];
                    data_in[out_bit_width*(i-1) +: out_bit_width] = data[i-1];
                end
                rd_count++;
            end
            if (write_data) begin
                wr_count++;
                if (data_out != prev_data_out+1) begin
                    $display("Error at wr_count %d, data_out: %d, prev_data_out: %d", wr_count, data_out, prev_data_out);
                end
                prev_data_out = data_out;
            end
            #10;
        end

        $finish;
    end

    always #5 clk = ~clk;  // 100 MHz clock with 10ns period
    //at multiples of 10, clk is low

endmodule
