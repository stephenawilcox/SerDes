/*
Copyright (c) 2025 Stephen Wilcox. All rights reserved
Not for use in commercial or non-commercial products or projects.
*/
`timescale 1ns/1ps
module deserializer_tb();
    parameter integer in_bit_width = 32;
    parameter integer out_bit_width = 512;

    reg clk, reset;

    reg data_ready;
    reg [in_bit_width-1:0] data_in;

    wire read_data, write_data;
    wire [out_bit_width-1:0] data_out;

    integer num_segments = out_bit_width / in_bit_width;

    reg [in_bit_width-1:0] data [256];
    reg [out_bit_width-1:0] exp_data_out;

    integer i, j, rd_count, wr_count;

    deserializer #(.in_bit_width(in_bit_width), .out_bit_width(out_bit_width)) des_inst (
        .clk(clk),
        .reset(reset),
        .data_ready(data_ready),
        .read_data(read_data),
        .data_in(data_in),
        .write_data(write_data),
        .data_out(data_out)
    );


    initial begin
        $dumpfile("deserializer.vcd");
        $dumpvars(0, deserializer_tb);

        rd_count = 0;
        wr_count = 0;
        exp_data_out = 0;

        reset = 1;
        clk = 0;
        #20;
        reset = 0;
        
        //setting data
        for (i = 0; i < 256; i++) begin
            data[i] = i;
            //$display("i: %d, data[i]: %d", i, data[i]);
        end
        data_ready = 1;

        for (j = 0; j < 256; j++) begin
            if (read_data) begin
                data_in = data[rd_count];
                rd_count++;
            end
            if (write_data) begin
                //setting exp_data_out
                for (i = (wr_count * num_segments)+1; i <= (wr_count * num_segments)+num_segments; i++) begin
                    //$display("write_data: %d, i-1: %d, data[i-1]: %d", write_data, i-1, data[i-1]);
                    exp_data_out[in_bit_width*(i-1) +: in_bit_width] = data[i-1];
                    //$display("exp_data_out: %h", exp_data_out);
                end
                wr_count++;
                if (data_out != exp_data_out) begin
                    // $display("Error at wr_count %d, data_out: %h, exp_data_out: %h", wr_count, data_out, exp_data_out);
                    $display("Error at wr_count %d,     data_out: %h", wr_count, data_out);
                    $display("Error at wr_count %d, exp_data_out: %h", wr_count, exp_data_out);
                    $display("");
                end
            end
            #10;
        end

        $finish;
    end

    always #5 clk = ~clk;  // 100 MHz clock with 10ns period
    //at multiples of 10, clk is low

endmodule