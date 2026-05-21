`timescale 1ns / 1ps
`include "baud_generator.v"
module receiver #(parameter baud = 2400, parameter dw = 8, parameter clk_freq = 50000000)(
	output reg [dw-1:0]rec_dataH,
	output reg rec_readyH,
	output reg rec_busy,
	input clk,
	input rst,
	input uart_REC_dataH
);

localparam idle  = 0;
localparam start = 1;
localparam data  = 2;
localparam stop  = 3;

wire baud_clk;
reg [1:0]st;
reg [$clog2(dw)-1:0] bit_count;
reg [dw-1:0] temp;
reg [3:0]samp;
reg F1, F2;

baud_generator #(.baud(baud), .clk_freq(clk_freq)) baud_generator(.clk(clk), .rst(rst), .baud_clk(baud_clk));
always@(posedge baud_clk or negedge rst)begin
if(!rst)begin
	F1 <= 1;
	F2 <= 1;
end

else begin
	F1 <= uart_REC_dataH;
	F2 <= F1;
end
end

always@(posedge baud_clk or negedge rst)begin
if(!rst)begin
	rec_dataH <= 0;
	rec_readyH <= 1;
	rec_busy <= 0;

	temp <= 0;
	bit_count <= 0;	
	
	st <= idle;
    samp <= 0;
end
else begin
//rec_readyH <= 0;
        case(st)
            idle: begin
                rec_busy <= 0;
                rec_readyH <= 1;
                samp<=0;
                bit_count<=0;
                if(F2 == 0)begin
                    //samp <= 0;
                    //rec_busy <= 1;
                    st <= start;
                end
            end
            start: begin
                rec_busy <= 1;
                rec_readyH <= 0;            
                     if(samp == 4)begin
                         samp <= 0;
                         if(F2 == 0) begin
                            //bit_count <= 0;
                            st <= data;
                         end
                         else begin
                            st <= idle;
                            //rec_busy <= 0;
                         end
                     end
                     else begin
                        samp <= samp + 1;
                     end
           end
           data: begin
                rec_busy <= 1;
                 rec_readyH <= 0;      
                    if(samp == 15)begin
                        temp[bit_count] <= F2;
                        samp <= 0;
                        if(bit_count == dw - 1)begin
                            bit_count <= 0;
                            st <= stop;
                        end
                        else begin
                            bit_count <= bit_count + 1;
                        end
                   end
                   else begin
                        samp <= samp + 1;
                   end
            end
            stop: begin
                rec_busy <= 1;
                rec_readyH <= 0;
                    if(samp == 15)begin
                            samp <= 0;
                            if(F2 == 1)begin
                                rec_dataH <= temp;
                                //rec_readyH <= 1;
                            end
                            if(F2==0) begin
                                rec_busy <= 1;
                                st <= start; 
                                rec_readyH<=0;
                            end
                            else begin
                                rec_busy <= 0;
                                st <= idle; 
                                rec_readyH<=1;
                            end                           
                    end
                    else begin
                        samp <= samp + 1;
                    end
            end
            endcase
        end
    end

endmodule

