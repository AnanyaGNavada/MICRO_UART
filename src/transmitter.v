`timescale 1ns / 1ps
`include "baud_generator.v"
module transmitter #(parameter baud = 2400, parameter dw = 8, parameter clk_freq = 50000000)(
    output reg uart_XMIT_dataH,
    output reg xmit_doneH,
    output reg xmit_active,
    input clk,
    input rst,
    input xmitH,
    input [dw-1:0] xmit_dataH
);

localparam idle  = 2'd0;
localparam start = 2'd1;
localparam data  = 2'd2;
localparam stop  = 2'd3;

wire baud_clk;

reg [1:0]             st,        next_st;
reg [$clog2(dw)-1:0] bit_count, next_bit_count;
reg [dw-1:0]         temp,      next_temp;
reg [3:0]            samp,      next_samp;

reg next_uart_XMIT_dataH;
reg next_xmit_doneH;
reg next_xmit_active;

baud_generator #(.baud(baud), .clk_freq(clk_freq))
    baud_gen (.clk(clk), .rst(rst), .baud_clk(baud_clk));

always @(posedge baud_clk or negedge rst) begin
    if (!rst) begin
        st              <= idle;
        temp            <= 0;
        bit_count       <= 0;
        samp            <= 0;
        uart_XMIT_dataH <= 1'b1;  
        xmit_doneH      <= 1'b1;   
        xmit_active     <= 1'b0;
    end else begin
        st              <= next_st;
        temp            <= next_temp;
        bit_count       <= next_bit_count;
        samp            <= next_samp;
        uart_XMIT_dataH <= next_uart_XMIT_dataH;
        xmit_doneH      <= next_xmit_doneH;
        xmit_active     <= next_xmit_active;
    end
end

always @(*) begin
    next_st              = st;
    next_temp            = temp;
    next_bit_count       = bit_count;
    next_samp            = samp;
    next_uart_XMIT_dataH = 1'b1;
    next_xmit_doneH      = 1'b0;   
    next_xmit_active     = 1'b0;

    case (st)

        idle: begin
            next_uart_XMIT_dataH = 1'b1;
            next_xmit_active     = 1'b0;
            next_xmit_doneH      = 1'b1;  
            next_bit_count       = 0;
            next_samp            = 0;

            if (xmitH) begin
                next_temp            = xmit_dataH;
                next_st              = start;
                next_xmit_active     = 1'b1;
                next_xmit_doneH      = 1'b0;
            end
        end

        start: begin
            next_uart_XMIT_dataH = 1'b0;   
            next_xmit_active     = 1'b1;
            next_xmit_doneH      = 1'b0;

            if (samp == 4'd15) begin
                next_samp = 0;
                next_st   = data;
            end else begin
                next_samp = samp + 1;
            end
        end

        data: begin
            next_uart_XMIT_dataH = temp[0];
            next_xmit_active     = 1'b1;
            next_xmit_doneH      = 1'b0;

            if (samp == 4'd15) begin
                next_samp = 0;
                next_temp = temp >> 1;

                if (bit_count == dw - 1) begin
                    next_bit_count = 0;
                    next_st        = stop;
                end else begin
                    next_bit_count = bit_count + 1;
                end
            end else begin
                next_samp = samp + 1;
            end
        end

        stop: begin
            next_uart_XMIT_dataH = 1'b1;   
            next_xmit_active     = 1'b1;
            next_xmit_doneH      = 1'b0;

            if (samp == 4'd15) begin
                next_samp        = 0;
                next_xmit_doneH  = 1'b1;   

                if (xmitH) begin
                    next_temp        = xmit_dataH;
                    next_st          = start;
                    next_xmit_active = 1'b1;
                end else begin
                    next_st          = idle;
                    next_xmit_active = 1'b0;
                end
            end else begin
                next_samp = samp + 1;
            end
        end

    endcase
end

endmodule

